#!/usr/bin/env nextflow
/*
 * Default pipeline parameters. They can be overriden on the command line eg.
 * given `params.foo` specify on the run command line `--foo some_value`.
 *
 * This nextflow pipeline is for lumpy-SV analysis.
 * Author: Qi Li (ql2387)
 */

Channel
        .fromPath(params.sampleList)
        .splitCsv(sep:'')
        .into {bamFileLoc1; bamFileLoc2}


log.info """\
 C N V - N F   P I P E L I N E
 ===================================
 reference      : ${params.reference}
 samtools       : ${params.samtools}
 lumpy          : ${params.lumpy}
 """


process extractDiscordantPairs {
        publishDir "${sample_file.baseName}", mode: 'move'
        tag "${sample_file.baseName}"

        input:
        path (sample_file) from bamFileLoc1

        output:
        set val(sample_file.baseName), file('*discordants.bam') into DiscordantPairs_ch
        file('*')

        script:
        """
        ln -s /nfs/archive/p2018/ALIGNMENT/BUILD37/DRAGEN/GENOME_AS_FAKE_EXOME/${sample_file.baseName}/${sample_file}.bai

        ${params.samtools}  view -b -F 1294 \
        $sample_file  {1..22} \
        > ${sample_file.baseName}.discordants.unsorted.bam

        ${params.samtools} sort ${sample_file.baseName}.discordants.unsorted.bam \
        -o ${sample_file.baseName}.discordants.bam
        """
}

process extractSplitRead {
        publishDir "${sample_file.baseName}", mode: 'move'
        tag "${sample_file.baseName}"

        input:
        path (sample_file) from bamFileLoc2

        output:
        set val(sample_file.baseName), file('*.splitters.bam') into SplitRead_ch
        file('*')

        script:
        """
        ln -s /nfs/archive/p2018/ALIGNMENT/BUILD37/DRAGEN/GENOME_AS_FAKE_EXOME/${sample_file.baseName}/${sample_file}.bai

        ${params.samtools}  view -h \
        $sample_file  {1..22} \
        | ${params.lumpy}/scripts/extractSplitReads_BwaMem -i stdin \
        | ${params.samtools} view -Sb - \
        > ${sample_file.baseName}.splitters.unsorted.bam

        ${params.samtools} sort ${sample_file.baseName}.splitters.unsorted.bam \
        -o ${sample_file.baseName}.splitters.bam
        """
}

process lumpyexpress {
		publishDir "${sample_file.baseName}", mode: 'copy'
        tag "${sample_file.baseName}"

		input:
        path (sample_file) from bamFileLoc1

        output:
        set val(sample_file.baseName), file('*vcf') into lumpy_ch

        script:
        """
		${params.lumpy}/bin/lumpyexpress \
		-K  ${params.lumpyConfig} \
		-B 	${sample_file} \
		-S  /nfs/external/az-ipf-garcia/lumpyCNV/${sample_file.baseName}/${sample_file.baseName}.splitters.bam \
		-D  /nfs/external/az-ipf-garcia/lumpyCNV/${sample_file.baseName}/${sample_file.baseName}.discordants.bam \
		-o  ${sample_file.baseName}.vcf
		"""
}

process VariantsToTable {
		publishDir "${sample_ID}", mode: 'move'
        tag "${sample_ID}"

		input:
		set val(sample_ID), file(VCFfile) from lumpy_ch

		output:
        file("*.txt")

        script:
        """
		${params.GATK} VariantsToTable \
		-V $VCFfile \
		-F CHROM -F POS -F ID -F ALT -F SVTYPE -F SVLEN \
		-GF SU -GF PE -GF SR \
		-O  ${sample_ID}.table.txt
		"""
}

workflow.onComplete {
        println ( workflow.success ? "COMPLETED!" : "FAILED" )
}
