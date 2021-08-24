##########################################################################
##########################################################################
##
##                                Library
##
##########################################################################
##########################################################################

import os, sys
from textwrap import dedent
import glob

import pandas as pd
from snakemake.utils import validate

##########################################################################
##########################################################################
##
##                               Functions
##
##########################################################################
##########################################################################

def get_final_output():
    """
    Generate final output name
    """
    final_output = multiext(os.path.join(OUTPUT_FOLDER,'results','plots','gene_PA'), 
    	'.png', '.pdf')
    return final_output

##########################################################################

def infer_gene_constrains(seed_table):
    '''
    Infer gene_constrains from default config value or table
    '''

    list_constrains = []

    for index, row in seed_table.iterrows() :
        if 'evalue' in seed_table.columns:
            tmp_eval = row.evalue
        else :
            tmp_eval = config['default_blast_option']['e_val']

        if 'coverage' in seed_table.columns:
            tmp_coverage = row.coverage
        else :
            tmp_coverage = config['default_blast_option']['cov']

        if 'pident' in seed_table.columns:
            tmp_pident = row.pident
        else :
            tmp_pident = config['default_blast_option']['pident']


        tmp_text = f'{row.seed}_evalue_{tmp_evalue:.0e}_cov_{tmp_coverage}_pid_{tmp_pident}'

        list_constrains.append(tmp_text)

    return list_constrains

##########################################################################

def infer_ngs_option(taxid):
    '''
    Infer taxid ngs option if not in taxid
    '''

    if 'NCBIGroups' not in taxid:
        taxid['NCBIGroups'] = config['ndg_option']['groups'] 


    return taxid

##########################################################################
##########################################################################
##
##                                Variables
##
##########################################################################
##########################################################################

# Validation of the config.yaml file
validate(config, schema="../schemas/config.schema.yaml")

# path to taxonomic id to search seeds in (TSV format, columns: TaxId, NCBIGroups)
taxid = config['taxid']

# path to seeds sheet (TSV format, columns: seed, protein_id, ...)
seed_file = config['seed'] 

# Name your project
project_name = config['project_name']

# Result folder
OUTPUT_FOLDER =  os.path.join(config['output_folder'], project_name)

# Psiblast default e-value thershold
e_val_psiblast = config['default_psiblast_option']['e_val'] 

# Option for ncbi_genome_download
section = config['ndg_option']['section'] 

# Values for assembly_levels :
assembly_levels = config['ndg_option']['assembly_levels'] 

# Values for refseq_categories : 
refseq_categories = config['ndg_option']['refseq_categories']

# Values for groups : 
taxid = infer_ngs_groups(taxid)

# Seepup option that create a reduce dataset using a psiblast step with the seed 
if config['speedup'] :
    speedup = os.path.join(OUTPUT_FOLDER, 'results', 
    				f'all_protein--eval_{e_val_psiblast:.0e}.fasta')
else  :
    speedup = os.path.join(OUTPUT_FOLDER, 'databases', 'all_taxid', 
    				'taxid_all_together.fasta')

# Definition of the requirements for each seed
gene_constrains = infer_gene_constrains(seed_table)


##########################################################################
##########################################################################
##
##                                Main
##
##########################################################################
##########################################################################

# Validation of the seed file
seed_table = (
    pd.read_table(seed_file)
    .set_index("seed", drop=False)
)

validate(seed_table, schema="../schemas/seeds.schema.yaml")

# Validation of the taxid file
taxid_table = (
    pd.read_table(taxid)
    .set_index("TaxId", drop=False)
)

validate(taxid_table, schema="../schemas/taxid.schema.yaml")
