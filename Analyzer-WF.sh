#!/bin/bash

# Author: Almog C
# Description: Automated forensic tool for HDD and RAM analysis

# Set the working directory to the current folder
HOME=$(pwd)
# Get the username of whoever's running this
USER=$(whoami)

# Function to zip files into one archive
function ZIP()
{
    # Go to the Volatility_Tool folder
    cd $HOME/Volatility_Tool
    # Zip everything in the folder named $NAME
    zip -r "Extracted_files.zip" "$NAME"
    rm -r $NAME

}

# Function to handle results depending on the mode
function RESULTS()
{
    # If we’re in HDD mode, do this
    if [ "$MODE" == "HDD" ]; then
        # Check if the strings file isn’t empty
        if [ -s $HOME/Volatility_Tool/$NAME/Strings.txt ]; then
            echo "Time of analysis: $(date)" | tee -a $HOME/Volatility_Tool/$NAME/Report.txt > /dev/null 2>&1
            echo "Files from Binwalk: $(ls $HOME/Volatility_Tool/$NAME/$file | wc -l)" | tee -a $HOME/Volatility_Tool/$NAME/Report.txt > /dev/null 2>&1
            echo "Files from Foremost: $(ls $HOME/Volatility_Tool/$NAME/Foremost | wc -l)" | tee -a $HOME/Volatility_Tool/$NAME/Report.txt > /dev/null 2>&1
            echo "Files from Bulk_Extractor: $(ls $HOME/Volatility_Tool/$NAME/Bulk_Extractor | wc -l)" | tee -a $HOME/Volatility_Tool/$NAME/Report.txt > /dev/null 2>&1
            echo "Stuff from Strings: $(ls $HOME/Volatility_Tool/$NAME/Strings.txt | wc -l)" | tee -a $HOME/Volatility_Tool/$NAME/Report.txt > /dev/null 2>&1
            echo "All findings are shown in the Report file."
        else
            echo "No results to report."
        fi
    fi

    # If we’re in RAM mode, do this
    if [ "$MODE" == "RAM" ]; then
        # Check if the Volatility results file isn’t empty
        if [ -s $HOME/Volatility_Tool/$NAME/Volatility_res.txt ]; then
            echo "Time of analysis: $(date)" | tee -a $HOME/Volatility_Tool/$NAME/Report.txt > /dev/null 2>&1
            echo "Stuff from Volatility: $(ls $HOME/Volatility_Tool/$NAME/Volatility_res.txt | wc -l)" | tee -a $HOME/Volatility_Tool/$NAME/Report.txt > /dev/null 2>&1
            echo "All findings are shown in the Report file."
        else
            echo "No results to report."
        fi
    fi
    # Zip everything up at the end
    ZIP
}

# Function to run all modes
function ALL()
{
    HDD
    VOLATILITY
}

# Function to analyze the HDD file
function HDD()
{
    MODE="HDD"
    # Make a directory to store results
    mkdir $HOME/Volatility_Tool/$NAME > /dev/null 2>&1
    cd $HOME/Volatility_Tool/$NAME

    # Run Binwalk
    echo "Running Binwalk..."
    sudo binwalk --run-as=root -e --directory=$HOME/Volatility_Tool/$NAME $file > /dev/null 2>&1

    # Run Foremost
    echo "Running Foremost..."
    sudo foremost -i $file -o $HOME/Volatility_Tool/$NAME/Foremost > /dev/null 2>&1

    # Run Bulk_Extractor
    echo "Running Bulk_Extractor..."
    sudo bulk_extractor $file -o $HOME/Volatility_Tool/$NAME/Bulk_Extractor > /dev/null 2>&1

    # Run Strings to find keywords
    echo "Running Strings..."
    sudo strings "$file" | grep -iE 'user|password|.exe' > "$HOME/Volatility_Tool/$NAME/Strings.txt" 2>/dev/null

    # Look for PCAP files
    ls -l $HOME/Volatility_Tool/$NAME/Bulk_Extractor | grep packets > /dev/null 2>&1
    if [ "$?" == "0" ]; then
        SIZE=$(ls -l $HOME/Volatility_Tool/$NAME/Bulk_Extractor | grep packets | awk '{print $5}')
        echo "Found a PCAP file! Size: $SIZE Location: $HOME/Volatility_Tool/$NAME/Bulk_Extractor"
    else
        echo "No PCAP file found."
    fi
    # Strats the RESULTS function
    RESULTS
}

# Function to analyze a RAM file
function VOLATILITY()
{
    MODE="RAM"
    # Find the memory profile name
    PROFILE=$($HOME/VOL -f $file imageinfo | grep "Suggested Profile" | awk -F',' '{print $1}' | awk -F':' '{print $2}' | sed 's/ //g')
    echo "Using memory profile: $PROFILE"

    # Make the output directory if it doesn’t exist
    if [ ! -d "$HOME/Volatility_Tool/$NAME" ]; then
        mkdir -p "$HOME/Volatility_Tool/$NAME"
    fi

    # Run Volatility commands
    PLUGIN=("pstree" "connscan" "hivelist" "printkey")
    for command in "${PLUGIN[@]}" ; do
        echo "Running: $command"
        $HOME/VOL -f $file --profile=$PROFILE $command | tee -a $HOME/Volatility_Tool/$NAME/Volatility_res.txt > /dev/null 2>&1
    done

    echo "Done analyzing $NAME! Results are saved in: $HOME/Volatility_Tool/$NAME/Volatility_res.txt"
    # Strats the RESULTS function
    RESULTS
}

# Function to install missing tools
function INSTALL()
{
    # Install Binwalk if it’s not there
	if [ -s /usr/bin/binwalk ]
	then
		echo "[+] Binwalk is already installed!"
	else
		echo "[!] Installing binwalk!"
		git clone https://github.com/ReFirmLabs/binwalk.git
		cd binwalk
		make
		make install
		
	fi

    # Install Foremost if it’s not there
	if [ -s /usr/bin/foremost ]
	then
		echo "[+] foremost is already installed!"
	else
		echo "[!] Installing foremost!"
		git clone https://github.com/gerryamurphy/Foremost.git
		cd foremost
		make
		make install
		
	fi

    # Install Bulk_Extractor if it’s not there
	if [ -s /usr/bin/bulk_extractor ]
	then
		echo "[+] bulk_extractor is already installed!"
	else
		echo "[!] Installing bulk_extractor!"
		git clone https://github.com/simsong/bulk_extractor.git
		cd bulk_extractor
		make
		make install
		
	fi

    # Install Strings if it’s not there
	if [ -s /usr/bin/strings ]
	then
		echo "[+] strings is already installed!"
	else
		echo "[!] Installing strings!"
		git clone https://github.com/glmcdona/strings2.git
		cd strings2
		make
		make install
		
	fi

	echo "DONE!"
	
	#Choose which kind of file you want to investigate
	echo "What memory file would you like to investigate? HDD/RAM/ALL"
	read answer
	if [ "$answer" == "HDD" ]
	then
		HDD
	elif [ "$answer" == "RAM" ]
	then
		VOLATILITY
	elif [ "$answer" == "ALL" ]
	then
		ALL
	else
		echo "Wrong input. try again."
		INSTALL
    fi
}

# Function to start the script
function START()
{
    # Get the current time
    TIME=$(date | awk '{print $4}')

    # Ask the user for the memory file path
    echo "Enter the full path to your memory file:"
    read file

    # Check if the file exists
    if [ -s $file ]; then
        NAME=$(basename $file)
        echo "Found the file: $NAME!"
        mkdir $HOME/Volatility_Tool > /dev/null 2>&1
        INSTALL
    else
        echo "Invalid file path! Try again."
        START
    fi

    # Check if the output directory already exists
    if [ -d $HOME/Volatility_Tool/$file ]; then
        echo "Looks like this file was already analyzed before."
    else
        mkdir $HOME/Volatility_Tool/$NAME > /dev/null 2>&1
    fi
}

# Making sure the script is run as root
if [ "$USER" == "root" ]; then
    echo "You’re running as root. Let’s go!"
    START
else
    echo "You’re not root. Please run as root and try again."
    exit
fi
