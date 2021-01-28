#!/bin/python3.6

import sys
import csv

batchFile = sys.argv[1]
SampleSheetUsed = sys.argv[2]
outFile = sys.argv[3]  # should end with _mqc.json for MultiQC

# Get all lines from get_stats.py output
with open(batchFile, 'r') as bFile:
    linesUnordered = [line.strip().split(',') for line in bFile]
unOrdSamples = [x[0] for x in linesUnordered]

# Get the order from SampleSheetUsed
samples = []
startReading = 0
with open(SampleSheetUsed, 'r') as file:
    lines = [line.strip() for line in file]
    for line in lines:
        if startReading == 1:  # Once reached [Data]
            samples.append(line.split(',')[1])
        if line.startswith("[Data]"):
            startReading = 1
# samples.pop() #Remove any empty are there empty line at end?!
samples = samples[1:]  # Remove header from SampleSheetUsed
sampleSheetSamples = [string for string in samples if string != ""]  # Remove empty fields
# Remove any HD829 because other pipeline
# HDindices = [i for i, x in enumerate(sampleSheetSamples) if x.startswith("HD829")]
# if len(HDindices) != 0 :
#     for index in HDindices:
#         sampleSheetSamples.pop(index)

# header = ['Sample','Tot seq','Reads mapped','Avg Coverage','Breadth 500x','Reads paired [%]','Insert size','Insert size s.d.',
#          'Average quality','Duplicates [%]','Breadth 50x','Breadth 100x','Bases on target']
# header = ['Sample','Total reads','Reads mapped [%]','HQ aligned reads','Mean Coverage','Chimeric reads [%]', 'Adapter [%]',
#          'Median insert size','Insert size s.d.','Average Quality','Fraction bases on target','Average CV']
header = [
    'Sample',
    'Total reads',
    'Reads aligned [%]',
    'Duplicates [%]',
    'Bases on target [%]',
    'Target bases over 100X [%]',
    'Mean target coverage',
    'Median target coverage',
    'Median insert size',
    'Insert size s.d.',
    'AT-dropout [%]',
    'GC-dropout [%]',
    'Target bases with zero coverage [%]',
    'FOLD-80',
]

with open(outFile, 'w') as file:
    # write all config for custom table
    file.write("{\n")
    file.write("  \"id\": \"qc_table\",\n")
    file.write("  \"section_name\": \"QC stats\",\n")
    file.write("  \"description\": \"QC-values from Picard, Samtools\",\n")
    file.write("  \"plot_type\": \"table\",\n")
    file.write("  \"pconfig\": {\n")
    file.write("    \"namespace\": \"qc-table\"\n")
    file.write("  },\n")
    file.write("  \"headers\": {\n")  # All header configs
    file.write('    \"Total reads\": {\n')
    file.write("      \"title\": \"Aligned reads\",\n")
    file.write("      \"description\": \"Number of reads in bam from Picard\",\n")
    file.write("      \"format\": \"{:.0f}\"\n")
    file.write('    },\n')
    file.write('    \"Reads aligned [%]\": {\n')
    file.write("      \"title\": \"Reads aligned [%]\",\n")
    file.write("      \"description\": \"Reads aligned [%] from Picard\",\n")
    file.write("      \"min\": 80,\n")
    file.write("      \"max\": 100,\n")
    file.write("      \"scale\": \"RdYlGn\",\n")
    file.write("      \"format\": \"{:.1f}\"\n")
    file.write("    },\n")
    file.write("    \"Duplicates [%]\": {\n")
    file.write("      \"title\": \"Duplicates [%]\",\n")
    file.write("      \"description\": \"Duplicates [%] from samtools stats (MarkDuplicates)\",\n")
    file.write("      \"min\": 0,\n")
    file.write("      \"max\": 40,\n")
    file.write("      \"scale\": \"RdYlGn-rev\",\n")
    file.write("      \"format\": \"{:.1f}\"\n")
    file.write("    },\n")
    file.write("    \"Bases on target [%]\": {\n")
    file.write("      \"title\": \"Bases on target [%]\",\n")
    file.write("      \"description\": \"Bases on target [%] from Picard\",\n")
    file.write("      \"min\": 50,\n")
    file.write("      \"max\": 100,\n")
    file.write("      \"scale\": \"RdYlGn\",\n")
    file.write("      \"format\": \"{:.1f}\"\n")
    file.write("    },\n")
    file.write("    \"Target bases over 100X [%]\": {\n")
    file.write("      \"title\": \"Target bases over 100X [%]\",\n")
    file.write("      \"description\": \"Target bases over 100X [%] from Picard\",\n")
    file.write("      \"min\": 50,\n")
    file.write("      \"max\": 100,\n")
    file.write("      \"scale\": \"RdYlGn\",\n")
    file.write("      \"format\": \"{:.1f}\"\n")
    file.write("    },\n")
    file.write('    \"Mean target coverage\": {\n')
    file.write("      \"title\": \"Mean target coverage\",\n")
    file.write("      \"description\": \"Mean target coverage from picard\",\n")
    file.write("      \"format\": \"{:.1f}\"\n")
    file.write("    },\n")
    file.write('    \"Median target coverage\": {\n')
    file.write("      \"title\": \"Median target coverage\",\n")
    file.write("      \"description\": \"Median target coverage from picard\",\n")
    file.write("      \"format\": \"{:.1f}\"\n")
    file.write("    },\n")
    file.write("    \"Median insert size\": {\n")
    file.write("      \"title\": \"Median insert size\",\n")
    file.write("      \"description\": \"Median insert size from Picard\",\n")
    file.write("      \"min\": 70,\n")
    file.write("      \"max\": 200,\n")
    file.write("      \"scale\": \"RdYlGn\"\n")
    file.write("      \"format\": \"{:.1f}\"\n")
    file.write("    },\n")
    file.write("    \"Insert size s.d.\": {\n")
    file.write("      \"title\": \"Insert size s.d.\",\n")
    file.write("      \"description\": \"Insert size standard deviation from Picard\",\n")
    file.write("      \"min\": 0,\n")
    file.write("      \"max\": 150,\n")
    file.write("      \"scale\": \"RdYlGn-rev\"\n")
    file.write("      \"format\": \"{:.1f}\"\n")
    file.write("    },\n")
    file.write("    \"AT-dropout [%]\": {\n")
    file.write("      \"title\": \"AT-dropout [%]\",\n")
    file.write("      \"description\": \"AT-dropout [%] from Picard\",\n")
    file.write("      \"min\": 0,\n")
    file.write("      \"max\": 1,\n")
    file.write("      \"scale\": \"RdYlGn-rev\",\n")
    file.write("      \"format\": \"{:.3f}\"\n")
    file.write("    },\n")
    file.write("    \"GC-dropout [%]\": {\n")
    file.write("      \"title\": \"GC-dropout [%]\",\n")
    file.write("      \"description\": \"GC-dropout [%] from Picard\",\n")
    file.write("      \"min\": 0,\n")
    file.write("      \"max\": 1,\n")
    file.write("      \"scale\": \"RdYlGn-rev\",\n")
    file.write("      \"format\": \"{:.3f}\"\n")
    file.write("    },\n")
    file.write("    \"Target bases with zero coverage [%]\": {\n")
    file.write("      \"title\": \"Target bases with zero coverage [%]\",\n")
    file.write("      \"description\": \"Target bases with zero coverage [%] from Picard\",\n")
    file.write("      \"min\": 0,\n")
    file.write("      \"max\": 10,\n")
    file.write("      \"scale\": \"RdYlGn-rev\",\n")
    file.write("      \"format\": \"{:.2f}\"\n")
    file.write("    },\n")
    file.write("    \"FOLD-80\": {\n")
    file.write("      \"title\": \"FOLD-80\",\n")
    file.write("      \"description\": \"FOLD-80 penalty from picard\",\n")
    file.write("      \"min\": 0,\n")
    file.write("      \"max\": 10,\n")
    file.write("      \"scale\": \"RdYlGn-rev\",\n")
    file.write("      \"format\": \"{:.1f}\"\n")
    file.write("    }\n")
    file.write("  },\n")  # Close headers

    # The table in samplesheet order
    file.write("  \"data\": {\n")
    for sample in sampleSheetSamples:
        line = linesUnordered[unOrdSamples.index(sample)]
        # 'sample1' :{ 4spaces
        file.write("    \"" + sample + "\": {\n")
        # 'col1': value1, 6spaces
        for i in range(1, len(header)):
            if i == len(header) - 1:
                file.write("      \"" + header[i] + "\": " + line[i] + "\n")
            else:
                file.write("      \"" + header[i] + "\": " + line[i] + ",\n")
        if sample == sampleSheetSamples[-1]:
            file.write('    }\n')
        else:
            file.write('    },\n')
    file.write('  }\n')  # close data

    file.write('}')
