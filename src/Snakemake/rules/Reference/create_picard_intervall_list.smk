rule picard_bed_to_interval_list:
    input:
        bed=config['bed']['bedfile'],
        dict=config['reference']['dict']
    output:
        config['bed']['interval_list']
    log:
        "logs/picard/bedtointervallist/interval_list.log"
    params:
        # optional parameters
        "SORT=true " # sort output interval list before writing
    # optional specification of memory usage of the JVM that snakemake will respect with global
    # resource restrictions (https://snakemake.readthedocs.io/en/latest/snakefiles/rules.html#resources)
    # and which can be used to request RAM during cluster job submission as `{resources.mem_mb}`:
    # https://snakemake.readthedocs.io/en/latest/executing/cluster.html#job-properties
    resources:
        mem_mb=1024
    container:
        config["singularity"].get("picard", config["singularity"].get("default", ""))
    wrapper:
        "v0.75.0/bio/picard/bedtointervallist"
