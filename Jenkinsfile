pipeline {
  agent { dockerfile {
      filename 'tests/dockerfiles/twist_dna_working.dockerfile'
      dir './'
      args '-u 0 --privileged -v $HOME/.m2:/home/jenkins/.m2 -v /beegfs-storage:/beegfs-storage:ro'

    }
  }
  stages {
    stage('Dry run tests') {
      steps {
        sh 'cp -r /data_twist_dna_fgbio . && snakemake -n -s /Twist_DNA/Twist_DNA.smk --directory ./data_twist_dna_fgbio'
        sh 'cp -r /data_twist_dna_markdup . && snakemake -n -s Twist_DNA.smk --directory ./data_twist_dna_markdup'
        sh 'cp -r /data_twist_dna_gpu . && snakemake -n -s Twist_DNA.smk --directory ./data_twist_dna_gpu'
        sh 'cp -r /data_twist_dna_cutadapt . && snakemake -n -s Twist_DNA.smk --directory ./data_twist_dna_cutadapt'
        sh 'cp -r /data_twist_dna_fastp . && snakemake -n -s Twist_DNA.smk --directory ./data_twist_dna_fastp'
        sh 'cp -r /data_gms_somatic . && snakemake -n -s gms_somatic.smk --directory ./data_gms_somatic/'
        sh 'cp -r /data_demultiplex . && snakemake -n -s demultiplex.smk --directory ./data_demultiplex/'
      }
    }
    stage('Small dataset') {
      steps {
        // /sh 'cd /data_gms_somatic && snakemake -j 2 -s /Twist_DNA/gms_somatic.smk --directory /data_gms_somatic --use-singularity --singularity-prefix /Twist_DNA --singularity-args  "--bind /beegfs-storage --bind /data --bind /Twist_DNA --bind /data_gms_somatic"'
        sh 'snakemake -j 2 -s /Twist_DNA/Twist_DNA.smk --directory /data_twist_dna_markdup --use-singularity --singularity-prefix /Twist_DNA --singularity-args  "--bind /beegfs-storage --bind /data --bind /Twist_DNA --bind /data_gms_somatic"'
      }
    }
  }
}
