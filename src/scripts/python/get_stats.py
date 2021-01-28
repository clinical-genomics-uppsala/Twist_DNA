#!/bin/python3.6
import sys
import subprocess
import csv

# picardDup = sys.argv[1]
picardMet1 = sys.argv[1]
picardMet2 = sys.argv[2]
picardMet3 = sys.argv[3]
picardMet4 = sys.argv[4]
samtools = sys.argv[5]
multiQCheader = sys.argv[6]
# cartoolLog = sys.argv[7]
sample = sys.argv[7]
outFile = sys.argv[8]
batchFile = sys.argv[9]

# Picard
metCmd = 'grep -A1 BAIT_SET ' + picardMet1
met = subprocess.run(metCmd, stdout=subprocess.PIPE, shell='TRUE').stdout.decode('utf-8')
metrics = met.split('\n')
zipObject = zip(metrics[0].split('\t'), metrics[1].split('\t'))
metricsDict1 = dict(zipObject)

metCmd = 'grep -A1 MEDIAN_INSERT_SIZE ' + picardMet2
met = subprocess.run(metCmd, stdout=subprocess.PIPE, shell='TRUE').stdout.decode('utf-8')
metrics = met.split('\n')
zipObject = zip(metrics[0].split('\t'), metrics[1].split('\t'))
metricsDict2 = dict(zipObject)

metCmd = 'grep -A3 CATEGORY ' + picardMet3
met = subprocess.run(metCmd, stdout=subprocess.PIPE, shell='TRUE').stdout.decode('utf-8')
metrics = met.split('\n')
zipObject = zip(metrics[0].split('\t'), metrics[3].split('\t'))
metricsDict3 = dict(zipObject)

metCmd = 'grep -A1 READS_USED ' + picardMet4
met = subprocess.run(metCmd, stdout=subprocess.PIPE, shell='TRUE').stdout.decode('utf-8')
metrics = met.split('\n')
zipObject = zip(metrics[0].split('\t'), metrics[1].split('\t'))
metricsDict4 = dict(zipObject)

# Samtools
samCmd = 'grep SN ' + samtools
sam = subprocess.run(samCmd, stdout=subprocess.PIPE, shell='TRUE').stdout.decode('utf-8').strip()
sam = sam.split('\nSN\t')
listOfList = [i.split('\t') for i in sam[1:]]
samDict = {item[0].strip(':'): item[1] for item in listOfList}

# Cartool
# avgCovCmd = 'grep "Mean Coverage Depth:" '+cartoolLog + ' |cut -f2 -d"," | cut -f1 -d" " '
# avgCov = subprocess.run(avgCovCmd, stdout=subprocess.PIPE,shell = 'TRUE').stdout.decode('utf-8')

# breadth500Cmd = 'grep "Mean Coverage Breadth:" '+cartoolLog + ' | cut -f3 -d"," '
# breadth500 = subprocess.run(breadth500Cmd, stdout=subprocess.PIPE,shell = 'TRUE').stdout.decode('utf-8')

# header = ['Sample','Total reads','Reads aligned [%]','HQ aligned reads','Mean Coverage','Chimeric reads [%]','Adapter [%]',
#          'Median insert size','Insert size s.d.','Average Quality','Fraction bases on target', 'Average CV']
# line = [sample, metricsDict3['TOTAL_READS'], metricsDict3['PCT_PF_READS_ALIGNED'], metricsDict3['PF_HQ_ALIGNED_READS'],
#        metricsDict1['MEAN_TARGET_COVERAGE'], metricsDict3['PCT_CHIMERAS'], metricsDict3['PCT_ADAPTER'],
#        metricsDict2['MEDIAN_INSERT_SIZE'], metricsDict2['STANDARD_DEVIATION'], samDict['average quality'],
#        metricsDict1['PCT_SELECTED_BASES'], str(Avg_500X_coverage)]
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
line = [
    sample,
    metricsDict3['TOTAL_READS'],
    100 * float(metricsDict3['PCT_PF_READS_ALIGNED']),
    100 * float(samDict['reads duplicated']) / float(samDict['raw total sequences']),
    100 * float(metricsDict1['PCT_SELECTED_BASES']),
    100 * float(metricsDict1['PCT_TARGET_BASES_100X']),
    metricsDict1['MEAN_TARGET_COVERAGE'],
    metricsDict1['MEDIAN_TARGET_COVERAGE'],
    metricsDict2['MEDIAN_INSERT_SIZE'],
    metricsDict2['STANDARD_DEVIATION'],
    100 * float(metricsDict4['AT_DROPOUT']),
    100 * float(metricsDict4['GC_DROPOUT']),
    100 * float(metricsDict1['ZERO_CVG_TARGETS_PCT']),
    metricsDict1['FOLD_80_BASE_PENALTY'],
]


# append to Batch file and write sampleFile
with open(batchFile, 'a') as file:
    writer = csv.writer(file, delimiter=',', lineterminator='\n')
    writer.writerow(line)

# Print multiQCheader
with open(multiQCheader, 'r') as f:
    with open(outFile, "w") as file:
        for mqcline in f:
            file.write(mqcline)
        writer = csv.writer(file, delimiter=',', lineterminator='\n')
        writer.writerow(header)
        writer.writerow(line)
