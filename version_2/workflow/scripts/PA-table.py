import pandas as pd

##########################################################################

def transform_proteinid(df):
    """
    get back the protein name without genomeid
    """

    for index, row in df.iterrows():
        protein_id = row.protein_id.split('--')[0]
        df.at[index, 'protein_id'] = protein_id

    return df

##########################################################################

# Seed preparing
seed_table = pd.read_table(snakemake.input.seed_file)
seed_list = seed_table.seed.to_list()

if 'color' in seed_table.columns:
    seed_color_dict = seed_table.set_index('seed').color.to_dict()
else :
    seed_color_dict = {seed:snakemake.config['default_values_plot']['color'] 
                          for seed in seed_list}

# list of all proteins
all_proteins = pd.read_table(snakemake.input.protein_table)

# fnodes opening
fam_id_table = pd.DataFrame()

for fnodes_file in snakemake.input.fnodes :
    tmp_df = pd.read_table(fnodes_file)
    fam_id_table = pd.concat([fam_id_table, tmp_df])

# add the protein information from the protein table and genome table
fam_id_table = fam_id_table.merge(all_proteins, on='protein_id')

# Retrieved protein_id
fam_id_table = transform_proteinid(fam_id_table)

# Table with number
patab = pd.crosstab(index = fam_id_table['genome_id'], columns = fam_id_table['seed'])

# To add missing seed if not find
seed_missing = [seed for seed in seed_list if seed not in patab.columns]
patab.loc[:,seed_missing] = 0

patab = patab[seed_list].sort_values(by = seed_list, ascending = False).reset_index()

# Add the genome name to the table in case needed
patab = patab.merge(fam_id_table[['genome_id','genome_name']].drop_duplicates(), on='genome_id')

patab = patab.melt(id_vars=['genome_id', 'genome_name'], var_name='seed', value_name='PA')

# Order the table by genome name to be more readable after
patab = patab.set_index('genome_id').loc[patab.genome_id.unique(),:].reset_index()

# Put color instead of number
for index, row in patab.iterrows():
    # Use the fact that 0 == False in python to test if it's 1 or 0
    if row.PA :
        patab.at[index, 'color'] = seed_color_dict[row.seed]
    else :
        patab.at[index, 'color'] = '#FFFFFF' # White color

patab = patab.merge(fam_id_table[['genome_id', 'seed', 'protein_id']], on=['genome_id', 'seed'], how='left')     
# save the table
patab.to_csv(snakemake.output.final_table, sep='\t', index=False)

# Because seems to be needed same table but in pivot format with the name of the protein in cells
patab_table = patab.pivot_table(index = 'genome_id', columns='seed', 
                                values='protein_id', aggfunc=proteins2csv, sort=False, dropna=False)[seed_list] 

patab_table.to_csv(snakemake.output.final_table_2, sep='\t')