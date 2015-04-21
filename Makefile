NULLGRAPH=../nullgraph
KHMER=../khmer
GRAPHALIGN=../2015-experimental-graphalign

all: simple-genome-reads.graph variants.txt

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

variants.txt: simple-genome-reads.graph
	 $(GRAPHALIGN)/find-variant-by-align-long.py simple-genome-reads.graph simple-genome-orig.fa --trusted 2 
