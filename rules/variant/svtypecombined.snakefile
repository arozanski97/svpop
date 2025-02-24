"""
Global rules for callers.
"""


#############
### Rules ###
#############


#
# Group variant calls and annotations - sv_all (ins/del/inv)
#

# variant_global_concat_anno_sv_insdelinv
#
# Concatenate annotations for SV types: ins, del, and inv.
rule variant_global_concat_anno_sv_insdelinv:
    input:
        tsv_ins='results/variant/{sourcetype}/{sourcename}/{sample}/{filter}/{svset}/anno/{annodir}/{annotype}_sv_ins.{ext}.gz',
        tsv_del='results/variant/{sourcetype}/{sourcename}/{sample}/{filter}/{svset}/anno/{annodir}/{annotype}_sv_del.{ext}.gz',
        tsv_inv='results/variant/{sourcetype}/{sourcename}/{sample}/{filter}/{svset}/anno/{annodir}/{annotype}_sv_inv.{ext}.gz'
    output:
        tsv_insdelinv='results/variant/{sourcetype}/{sourcename}/{sample}/{filter}/{svset}/anno/{annodir}/{annotype}_sv_insdelinv.{ext,tsv|bed}.gz'
    run:

        # Concat
        df = svpoplib.pd.concat_frames(
            [pd.read_csv(file_name, sep='\t', header=0) for file_name in input]
        )

        # Sort
        sort_cols = [col for col in df.columns if col in {'#CHROM', 'POS', 'END', 'ID'}]

        if len(sort_cols) > 0:
            df = df.sort_values(sort_cols)

        # Write
        df.to_csv(output.tsv_insdelinv, sep='\t', index=False, compression='gzip')

# variant_global_concat_sv_insdelinv
#
# Concatenate SV types: ins, del, and inv.
rule variant_global_concat_sv_insdelinv:
    input:
        sv_ins='results/variant/{sourcetype}/{sourcename}/{sample}/{filter}/all/bed/sv_ins.bed.gz',
        sv_del='results/variant/{sourcetype}/{sourcename}/{sample}/{filter}/all/bed/sv_del.bed.gz',
        sv_inv='results/variant/{sourcetype}/{sourcename}/{sample}/{filter}/all/bed/sv_inv.bed.gz'
    output:
        all_bed='results/variant/{sourcetype}/{sourcename}/{sample}/{filter}/{svset}/bed/sv_insdelinv.bed.gz'
    run:

        svpoplib.pd.concat_frames(
            [pd.read_csv(file_name, header=0, sep='\t') for file_name in input]
        ).sort_values(
            ['#CHROM', 'POS', 'END', 'ID']
        ).to_csv(
            output.all_bed, sep='\t', index=False, compression='gzip'
        )


#
# Group variant calls and annotations - insdel
#

# variant_global_concat_anno_insdel
#
# Concatenate annotations.
rule variant_global_concat_anno_insdel:
    input:
        tsv_ins='results/variant/{sourcetype}/{sourcename}/{sample}/{filter}/{svset}/anno/{annodir}/{annotype}_{vartype}_ins.{ext}.gz',
        tsv_del='results/variant/{sourcetype}/{sourcename}/{sample}/{filter}/{svset}/anno/{annodir}/{annotype}_{vartype}_del.{ext}.gz'
    output:
        tsv_all='results/variant/{sourcetype}/{sourcename}/{sample}/{filter}/{svset}/anno/{annodir}/{annotype}_{vartype}_insdel.{ext}.gz'
    wildcard_constraints:
        ext='tsv|bed'
    run:

        # Concat
        df = svpoplib.pd.concat_frames(
            [pd.read_csv(file_name, sep='\t', header=0) for file_name in input]
        )

        # Sort
        sort_cols = [col for col in df.columns if col in {'#CHROM', 'POS', 'END', 'ID'}]

        if len(sort_cols) > 0:
            df = df.sort_values(sort_cols)

        # Write
        df.to_csv(output.tsv_all, sep='\t', index=False, compression='gzip')

# variant_global_concat_insdel
#
# Concatenate all SV types (ins, del, and inv).
rule variant_global_concat_insdel:
    input:
        sv_ins='results/variant/{sourcetype}/{sourcename}/{sample}/{filter}/{svset}/bed/{vartype}_ins.bed.gz',
        sv_del='results/variant/{sourcetype}/{sourcename}/{sample}/{filter}/{svset}/bed/{vartype}_del.bed.gz'
    output:
        all_bed='results/variant/{sourcetype}/{sourcename}/{sample}/{filter}/{svset}/bed/{vartype}_insdel.bed.gz'
    run:

        svpoplib.pd.concat_frames(
            [pd.read_csv(file_name, sep='\t', header=0) for file_name in input]
        ).sort_values(
            ['#CHROM', 'POS', 'END', 'ID']
        ).to_csv(
            output.all_bed, sep='\t', index=False, compression='gzip'
        )

# variant_global_concat_insdel_fa
#
# Concatenate insertion and deletion records into one FASTA.
rule variant_global_concat_insdel_fa:
    input:
        fa_ins='results/variant/{sourcetype}/{sourcename}/{sample}/{filter}/{svset}/bed/fa/{vartype}_ins.fa.gz',
        fa_del='results/variant/{sourcetype}/{sourcename}/{sample}/{filter}/{svset}/bed/fa/{vartype}_del.fa.gz'
    output:
        fa='results/variant/{sourcetype}/{sourcename}/{sample}/{filter}/{svset}/bed/fa/{vartype}_insdel.fa.gz',
        fai='results/variant/{sourcetype}/{sourcename}/{sample}/{filter}/{svset}/bed/fa/{vartype}_insdel.fa.gz.fai'
    run:

        def get_fa_iter():
            for in_file_name in (input.fa_ins, input.fa_del):
                with gzip.open(in_file_name, 'rt') as in_file:
                    for record in SeqIO.parse(in_file, 'fasta'):
                        yield record

        with Bio.bgzf.BgzfWriter(output.fa, 'wb') as out_file:
            SeqIO.write(get_fa_iter(), out_file, 'fasta')

        shell("""samtools faidx {output.fa}""")


# variant_global_concat_all_fa
#
# Concatenate insertion, deletion, and inversion records into one FASTA.
rule variant_global_concat_insdelinv_fa:
    input:
        fa_ins='results/variant/{sourcetype}/{sourcename}/{sample}/{filter}/{svset}/bed/fa/{vartype}_ins.fa.gz',
        fa_del='results/variant/{sourcetype}/{sourcename}/{sample}/{filter}/{svset}/bed/fa/{vartype}_del.fa.gz',
        fa_inv='results/variant/{sourcetype}/{sourcename}/{sample}/{filter}/{svset}/bed/fa/{vartype}_inv.fa.gz'
    output:
        fa='results/variant/{sourcetype}/{sourcename}/{sample}/{filter}/{svset}/bed/fa/{vartype}_insdelinv.fa.gz',
        fai='results/variant/{sourcetype}/{sourcename}/{sample}/{filter}/{svset}/bed/fa/{vartype}_insdelinv.fa.gz.fai'
    run:

        def get_fa_iter():
            for in_file_name in (input.fa_ins, input.fa_del, input.fa_inv):
                with gzip.open(in_file_name, 'rt') as in_file:
                    for record in SeqIO.parse(in_file, 'fasta'):
                        yield record

        with Bio.bgzf.BgzfWriter(output.fa, 'wb') as out_file:
            SeqIO.write(get_fa_iter(), out_file, 'fasta')

        shell("""samtools faidx {output.fa}""")
