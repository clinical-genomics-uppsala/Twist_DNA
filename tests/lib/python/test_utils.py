# coding: utf-8

import os
import unittest
import shutil
import tempfile


class TestUtilMethods(unittest.TestCase):
    def setUp(self):
        pass

    def tearDown(self):
        pass

    def test_generate_sample_list(self):
        from src.lib.python.utils import generate_sample_list_from_samplesheet

        data = generate_sample_list_from_samplesheet("tests/samplesheets/samplesheet1.csv")
        self.assertEqual(data, {
            "29948": {"counter": 1, "projectpath": ""},
            "D21-00844": {"counter": 2, "projectpath": ""},
            "29949": {"counter": 3, "projectpath": ""},
            "D21-00845": {"counter": 4, "projectpath": ""}})

        data = generate_sample_list_from_samplesheet("tests/samplesheets/samplesheet2.csv")
        self.assertEqual(data, {
            "29948": {"counter": 1, "projectpath": "WP3/"},
            "D21-00844": {"counter": 2, "projectpath": "WP2/"},
            "29949": {"counter": 3, "projectpath": "WP3/"},
            "D21-00845": {"counter": 4, "projectpath": "WP2/"}})

    def test_get_fastq_file(self):
        import pandas as pd
        from src.lib.python.utils import get_fastq_file

        units = pd.read_table("tests/lib/python/files/units.tsv", index_col=["sample", "unit"], dtype=str)
        units.index = units.index.set_levels([i.astype(str) for i in units.index.levels])

        self.assertEqual(get_fastq_file(units,"sample1","lane1","fq1"), "fastq/sample1/sample1_S1_L001_R1_001.fastq")
        self.assertEqual(get_fastq_file(units,"sample1","lane1","fq2"), "fastq/sample1/sample1_S1_L001_R2_001.fastq")
        self.assertEqual(get_fastq_file(units,"sample1","lane2","fq1"), "fastq/sample1/sample1_S1_L002_R1_001.fastq")
        self.assertEqual(get_fastq_file(units,"sample1","lane2","fq2"), "fastq/sample1/sample1_S1_L002_R2_001.fastq")
        self.assertEqual(get_fastq_file(units,"sample2","rep1","fq1"), "fastq/sample2_S2_L001_R1_001.fastq")
        self.assertEqual(get_fastq_file(units,"sample2","rep1","fq2"), "fastq/sample2_S2_L001_R2_001.fastq")

    def test_num_units(self):
        import pandas as pd
        from src.lib.python.utils import get_num_units

        units = pd.read_table("tests/lib/python/files/units.tsv", index_col=["sample", "unit"], dtype=str)
        units.index = units.index.set_levels([i.astype(str) for i in units.index.levels])

        self.assertEqual(get_num_units(units,"sample1"), 2)
        self.assertEqual(get_num_units(units,"sample2"), 1)

    def test_get_units(self):
        import pandas as pd
        from src.lib.python.utils import get_units

        units = pd.read_table("tests/lib/python/files/units.tsv", index_col=["sample", "unit"], dtype=str)
        units.index = units.index.set_levels([i.astype(str) for i in units.index.levels])

        self.assertEqual(get_units(units,"sample1"), ['lane1', 'lane2'])
        self.assertEqual(get_units(units,"sample2"), ['rep1'])
