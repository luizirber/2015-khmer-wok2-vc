NULLGRAPH=../nullgraph
KHMER=../khmer
GRAPHALIGN=../2015-experimental-graphalign
MOLECULO_READS=~/galGal/inputs/moleculo

all: variants-patched.txt ecoli.align.out variants-sim.txt

clean:
	-rm simple-genome-reads.fa

simple-genome.fa:
	$(NULLGRAPH)/make-random-genome.py -l 1000 -s 1 > simple-genome.fa

simple-genome-reads.fa: simple-genome.fa
	$(NULLGRAPH)/make-reads.py -S 1 -e .01 -r 100 -C 100 simple-genome.fa --mutation-details simple-genome-reads.mut > simple-genome-reads.fa

simple-genome-reads.graph: simple-genome-reads.fa
	normalize-by-median.py -C 20 -k 20 -x 1e7 -N 4 simple-genome-reads.fa -s simple-genome-reads.ct
	filter-abund.py -C 3 simple-genome-reads.ct simple-genome-reads.fa.keep
	normalize-by-median.py -C 5 -k 20 -x 1e7 -N 4 simple-genome-reads.fa.keep.abundfilt -s simple-genome-reads.graph

variants-sim.txt: simple-genome-reads.graph
	 $(GRAPHALIGN)/find-variant-by-align-long.py simple-genome-reads.graph simple-genome-orig.fa --trusted 2 --variants-out variants-sim.txt

ecoliMG1655.fa:
	wget -SNc https://github.com/ctb/edda/raw/master/doc/tutorials-2012/files/ecoliMG1655.fa.gz

ecoli-mapped.fq.gz.keep.gz: ecoli-mapped.fq.gz
	normalize-by-median.py -k 21 -x 1e8 -N 4 ecoli-mapped.fq.gz
	gzip ecoli-mapped.fq.gz.keep

ecoli.dn.k21.kh: ecoli-mapped.fq.gz.keep.gz
	load-into-counting.py -k 21 -x 8e7 ecoli.dn.k21.kh ecoli-mapped.fq.gz.keep.gz

ecoli.align.out: ecoli.dn.k21.kh
	$(GRAPHALIGN)/find-variant-by-align-long.py ecoli.dn.k21.kh ecoliMG1655.fa --variants-out variants-ecoli.txt > ecoli.align.out

ecoli-patched.fa: ecoliMG1655.fa
	python patch-ecoli.py ecoliMG1655.fa > ecoli-patched.fa 2> ecoli-patch-segments.fa

ecoli-patched.align.out: ecoli.dn.k21.kh ecoli-patched.fa
	$(GRAPHALIGN)/find-variant-by-align-long.py ecoli.dn.k21.kh ecoli-patched.fa --variants-out variants-patched.txt > ecoli-patched.align.out

###############################

galGal4.fa.gz:
	wget -SNc ftp://hgdownload.cse.ucsc.edu/goldenPath/galGal4/bigZips/$(@F)

galGal4.fixed.fa.gz: galGal4.fa.gz
	python fix_reference.py $< $@

###############################

galGal4.fixed.k21.kh: galGal4.fixed.fa.gz
	load-into-counting.py -k 21 -x 7e9 $@ $<

galGal4.fixed.align.out: galGal4.fixed.k21.kh $(MOLECULO_READS)/LR6000017-DNA_A01-LRAAA-1_LongRead.fastq.gz
	$(GRAPHALIGN)/find-variant-by-align-long.py --trusted 1 $^ --variants-out variants-galGal4-fixed.txt > $@

###############################

# Estimated unique kmers: 904.369.109
moleculo.k21.kh: $(wildcard $(MOLECULO_READS)/*.fastq.gz)
	load-into-counting.py -k 21 -N 6 -x 2e9 $@ $^

moleculo.align.out: moleculo.k21.kh galGal4.fixed.fa.gz
	$(GRAPHALIGN)/find-variant-by-align-long.py --trusted 5 $^ --variants-out variants-galGal4-fixed.txt > $@

###############################

moleculo.align.out.pbs:
	JOBID=`echo make moleculo.align.out | cat header.sub - footer.sub | \
          qsub -l walltime=30:00:00,nodes=1:ppn=1,mem=60gb -A ged -N moleculo.align -o $@ -e $@.err | cut -d"." -f1` ; \
	while [ -n "$$(qstat -a |grep $${JOBID})" ]; do sleep 600; done
	@grep "PBS job finished: SUCCESS" $@

###############################

# Estimated unique kmers: 31.029.591
galGal4.fixed.k13.kh: galGal4.fixed.fa.gz
	load-into-counting.py -k 13 -N 6 -x 5e7 $@ $<

galGal4.fixed.k13.align.out: galGal4.fixed.k13.kh $(MOLECULO_READS)/LR6000017-DNA_A01-LRAAA-1_LongRead.fastq.gz
	$(GRAPHALIGN)/find-variant-by-align-long.py --trusted 1 $^ --variants-out variants-galGal4-fixed.txt > $@

galGal4.fixed.k13.align.out.pbs:
	JOBID=`echo make galGal4.fixed.k13.align.out | cat header.sub - footer.sub | \
          qsub -l walltime=60:00:00,nodes=1:ppn=1,mem=60gb -A ged -N galGal4.fixed.k13.align -o $@ -e $@.err | cut -d"." -f1` ; \
	while [ -n "$$(qstat -a |grep $${JOBID})" ]; do sleep 600; done
	@grep "PBS job finished: SUCCESS" $@

###############################

# Estimated unique kmers: 30.326.293
moleculo.k13.kh: $(wildcard $(MOLECULO_READS)/*.fastq.gz)
	load-into-counting.py -k 13 -N 6 -x 5e7 $@ $^

moleculo.k13.align.out: moleculo.k13.kh galGal4.fixed.fa.gz
	$(GRAPHALIGN)/find-variant-by-align-long.py --trusted 5 $^ --variants-out variants-galGal4-fixed.txt > $@

moleculo.k13.align.out.pbs:
	JOBID=`echo make moleculo.k13.align.out | cat header.sub - footer.sub | \
          qsub -l walltime=10:00:00,nodes=1:ppn=1,mem=60gb -A ged -N moleculo.k13.align -o $@ -e $@.err | cut -d"." -f1` ; \
	while [ -n "$$(qstat -a |grep $${JOBID})" ]; do sleep 600; done
	@grep "PBS job finished: SUCCESS" $@

.SECONDARY:
.PRECIOUS: galGal4.fixed.align.out moleculo.align.out galGal4.fixed.k13.align.out moleculo.k13.align.out
