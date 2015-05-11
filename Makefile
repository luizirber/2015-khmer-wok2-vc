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

galGal4.fa.gz.keep.gz: galGal4.fa.gz
	normalize-by-median.py -C 1 -k 21 -x 7e9 -N 4 -R $@.info $<
	gzip $(<).keep

galGal4.dn.k21.kh: galGal4.fa.gz.keep.gz
	load-into-counting.py -k 21 -x 7e9 $@ $<

galGal4.k21.kh: galGal4.fa.gz
	load-into-counting.py -k 21 -x 7e9 $@ $<

galGal4.align.out: galGal4.dn.k21.kh $(MOLECULO_READS)/LR6000017-DNA_A01-LRAAA-1_LongRead.fastq.gz
	$(GRAPHALIGN)/find-variant-by-align-long.py $^ --variants-out variants-galGal4.txt > $@

###############################

galGal-mapped.fq.gz.keep.gz: $(MOLECULO_READS)/LR6000017-DNA_A01-LRAAA-1_LongRead.fastq.gz
	normalize-by-median.py -k 21 -x 1e8 -N 4 $<
	gzip $(<).keep.gz

galGal.dn.k21.kh: galGal-mapped.fq.gz.keep.gz
	load-into-counting.py -k 21 -x 8e7 $@ $<

galGal.align.out: galGal.dn.k21.kh galGal4.fa.gz
	$(GRAPHALIGN)/find-variant-by-align-long.py $^ --variants-out variants-galGal.txt > $@
