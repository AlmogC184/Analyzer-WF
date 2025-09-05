# Analyzer-WF
An automated tool designed to analyze both HDD images (disk files) and RAM dumps (memory images). It leverages Binwalk, Foremost, Bulk Extractor, Strings, and Volatility to extract and analyze metadata. All results are organized and packaged into a zip file for easy review.

Usage Instructions:
Make sure you are running a Linux system with root privileges, since some tools require elevated access.

Clone the repository:
git clone https://github.com/AlmogC184/Analyzer-WF.git

Move to folder:
cd Analyzer-WF

Make the script executable:
chmod +x Analyzer-WF.sh

Run the script as root:
sudo ./Analyzer-WF.sh

When prompted, enter the full path to the memory or disk file you want to analyze.

Choose the mode of analysis:

HDD – for disk images

RAM – for memory dumps

ALL – to run both HDD and RAM analysis

The script will:

Create a folder for the analysis results.
Run the appropriate tools to extract files and metadata.
Generate a summary report.
Package all results into a zip file in the same folder.

To view the results navigate to the created folder (same name as the file you analyzed) , inside Volatility_Tool/.
Open Report.txt to see a summary of findings.
Extract the zip file to view the full outputs from each tool.

Notes!

Running as root is required for some tools, but exercise caution.
Large disk or memory files may take time to process.
The script is intended for educational and forensic analysis practice only!
