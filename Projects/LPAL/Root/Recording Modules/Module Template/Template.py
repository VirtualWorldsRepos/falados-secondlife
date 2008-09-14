from __future__ import with_statement
import re

attributes = {};

def AddAttribute(name,code):
	attributes[name] = code;

def ResetAttributes():
	attributes = {}

def GenerateFile(template_file,out_file):
        pat = re.compile("<<([A-Za-z_ ]+)>>")
        with open(template_file) as f:
                with open(out_file,"w") as o:
                        for line in f:
                                for m in pat.finditer(line):
                                        if attributes.has_key(m.group(1)):
                                                line = line[:m.start(0)] + attributes[m.group(1)] + line[m.end(0):]
                                o.write(line);
