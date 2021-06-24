
localrules:
    all,
    Create_Twist_DNA_yaml,


rule all:
    input:
        Twist_DNA_yaml="Twist_DNA.yaml",  # TC="DATA/Pathological_purity_BMS_validation.txt",


rule Create_Twist_DNA_yaml:
    input:
        run_info="RunParameters.xml",
        config="Config/Pipeline/configdefaults201012.yaml",
    output:
        # TC="DATA/Pathological_purity_BMS_validation.txt",
        Twist_DNA_yaml="Twist_DNA.yaml",
        samples_tsv="samples.tsv",
        units_tsv="units.tsv",
    run:
        import glob
        import os
        import subprocess

        subprocess.call("cp " + input.config + " " + output.Twist_DNA_yaml, shell=True)
        run_folder_name = ""
        run_info_file = open(input.run_info)
        for line in run_info_file:
            if line.find("<RunID>") != -1:
                run_folder_name = line.split(">")[1].split("<")[0]
        state = 0
        DNA_sample_list = []
        i = 1
        sample_sheet_name = glob.glob("*heet.csv")
        if len(sample_sheet_name) > 1:
            print("Error: Something wrong with the sample sheet name!")
            quit()
        sample_sheet_name = sample_sheet_name[0]
        infile = open(sample_sheet_name)
        for line in infile:
            if state == 0:
                if line.find("Experiment Name") != -1:
                    state = 1
            elif state == 1:
                if line.find("Lane,Sample_ID") != -1:
                    state = 2
            elif state == 2:
                lline = line.strip().split(",")
                sample = lline[1]
                if sample.find(" ") != -1:
                    print("incorrect sample name: " + sample)
                    quit()
                TC = lline[11]
                DNA_sample_list.append([sample, i, TC])
                i += 1
        outfile = open(output.Twist_DNA_yaml, "a")
        outfile_samples = open(output.samples_tsv, "w")
        outfile_units = open(output.units_tsv, "w")
        outfile.write("runfolder_path: /projects/wp1/nobackup/ngs/klinik/INBOX/" + run_folder_name + "/\n")
        outfile.write("samplesheet: /projects/wp1/nobackup/ngs/klinik/INBOX/" + run_folder_name + "/" + sample_sheet_name + "\n")
        outfile.write("bcl2fastq_version: 2.17.1.14\n\n")
        # outfile.write("DNA_Samples:\n")

        outfile_samples.write("sample\tTC\tplatform")
        outfile_units.write("sample\tunit\tfq1\tfq2")

        for sample in DNA_sample_list:
            # outfile.write("  " + sample[0] + ": \"S" + str(sample[1]) + "\"\n")
            outfile_samples.write("\n" + sample[0] + "\t" + str(sample[2]) + "\tNextSeq")
            outfile_units.write(
                "\n"
                + sample[0]
                + "\tL000\t"
                + "fastq/DNA/"
                + sample[0]
                + "_R1.fastq.gz\t"
                + "fastq/DNA/"
                + sample[0]
                + "_R2.fastq.gz"
            )

        outfile.write("\nsamples: " + output.samples_tsv)
        outfile.write("\n#units: " + output.units_tsv)

        outfile.close()
