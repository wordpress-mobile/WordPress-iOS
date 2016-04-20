#!/usr/bin/env python
# -*- coding: utf-8 -*-

# This program is free software. It comes without any warranty, to
# the extent permitted by applicable law. You can redistribute it
# and/or modify it under the terms of the Do What The Fuck You Want
# To Public License, Version 2, as published by Sam Hocevar. See
# http://sam.zoy.org/wtfpl/COPYING for more details.
# 
# Localize.py - Incremental localization on XCode projects
# João Moreno 2009
# http://joaomoreno.com/

from sys import argv
from codecs import open
from re import compile
from copy import copy
import os

re_translation = compile(r'^"(.+)" = "(.+)";$')
re_comment_single = compile(r'^/(/.*|\*.*\*/)$')
re_comment_start = compile(r'^/\*.*$')
re_comment_end = compile(r'^.*\*/$')

def print_help():
    print u"""Usage: merge.py merged_file old_file new_file
Xcode localizable strings merger script. João Moreno 2009."""

class LocalizedString():
    def __init__(self, comments, translation):
        self.comments, self.translation = comments, translation
        self.key, self.value = re_translation.match(self.translation).groups()

    def __unicode__(self):
        return u'%s%s\n' % (u''.join(self.comments), self.translation)

class LocalizedFile():
    def __init__(self, fname=None, auto_read=False):
        self.fname = fname
        self.strings = []
        self.strings_d = {}

        if auto_read:
            self.read_from_file(fname)

    def read_from_file(self, fname=None):
        fname = self.fname if fname == None else fname
        try:
            f = open(fname, encoding='utf_16', mode='r')
        except:
            print 'File %s does not exist.' % fname
            exit(-1)
        
        line = f.readline()
        while line and line == u'\n':
            line = f.readline()

        while line:
            comments = [line]

            if not re_comment_single.match(line):
                while line and not re_comment_end.match(line):
                    line = f.readline()
                    comments.append(line)
            
            line = f.readline()
            if line and re_translation.match(line):
                translation = line
            else:
                raise Exception('invalid file: %s' % line)
            
            line = f.readline()
            while line and line == u'\n':
                line = f.readline()

            string = LocalizedString(comments, translation)
            self.strings.append(string)
            self.strings_d[string.key] = string

        f.close()

    def save_to_file(self, fname=None):
        fname = self.fname if fname == None else fname
        try:
            f = open(fname, encoding='utf_16', mode='w')
        except:
            print 'Couldn\'t open file %s.' % fname
            exit(-1)

        for string in self.strings:
            f.write(string.__unicode__())

        f.close()

    def merge_with(self, new):
        merged = LocalizedFile()

        for string in new.strings:
            if self.strings_d.has_key(string.key):
                new_string = copy(self.strings_d[string.key])
                new_string.comments = string.comments
                string = new_string

            merged.strings.append(string)
            merged.strings_d[string.key] = string

        return merged

def merge(merged_fname, old_fname, new_fname):
    try:
        old = LocalizedFile(old_fname, auto_read=True)
        new = LocalizedFile(new_fname, auto_read=True)
    except Exception as e:
        print 'Error: input files have invalid format. old: %s, new: %s' % (old_fname, new_fname)
        print e

    merged = old.merge_with(new)

    merged.save_to_file(merged_fname)

STRINGS_FILE = 'Localizable.strings'

def localize(path):
    if "Scripts" in path:
        print "Must run script from the root folder"
        quit()

    os.chdir(path)
    resources_path = os.path.join(path, 'Resources')
    language = os.path.join(resources_path, 'en.lproj')

    original = merged = language + os.path.sep + STRINGS_FILE
    old = original + '.old'
    new = original + '.new'

    if os.path.isfile(original):
        os.rename(original, old)
        os.system('genstrings -q -o "%s" `find . ../Pods/WordPress* ../Pods/WPMediaPicker -name "*.m" -o -name "*.swift" | grep -v Vendor`' % language)
        os.rename(original, new)
        merge(merged, old, new)
        os.remove(new)
        os.remove(old)
    else:
        os.system('genstrings -q -o "%s" `find . -name "*.m" -o -name "*.swift"` | grep -v Vendor' % language)

if __name__ == '__main__':
    localize(os.path.join(os.getcwd(), 'WordPress'))

