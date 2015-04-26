#! /usr/bin/env python
import sys
import screed
import argparse

parser = argparse.ArgumentParser()
parser.add_argument('genome')
args = parser.parse_args()

genome = list([ r for r in screed.open(args.genome) ])[0]

patchseq = genome.sequence
#print >>sys.stderr, patchseq[1000000]
patchseq = patchseq[:1000000] + 'c' + patchseq[1000001:]
#print >>sys.stderr, patchseq[1000000]
print >>sys.stderr, '>a1000000\n%s' % (patchseq[999900:1000100],)

patchseq = genome.sequence
#print >>sys.stderr, patchseq[2000000:2000002]
patchseq = patchseq[:2000000] + patchseq[2000002:]
#print >>sys.stderr, patchseq[2000000:2000002]
print >>sys.stderr, '>b2000000\n%s' % (patchseq[1999900:2000100],)

patchseq = genome.sequence
#print >>sys.stderr, patchseq[3000000:3000002]
patchseq = patchseq[:3000000] + 'gg' + patchseq[3000000:]
#print >>sys.stderr, patchseq[3000000:3000002]
print >>sys.stderr, '>c3000000\n%s' % (patchseq[2999900:3000100],)

print '>%s\n%s' % (genome.name, patchseq)
