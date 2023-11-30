#!/usr/bin/python
# -*- coding: UTF-8 -*-

import os
import re

protoId = 0
protoIdDict = {}
availableIdList = []
protoDict = {}
protoFile = "./proto.lua"
os.system("protoc -o all.pb *.proto */*.proto")

def getProtoId(protoName):
    if len(availableIdList) > 0:
        return availableIdList.pop()
    global protoId
    protoId = protoId + 1
    return protoId

def removeSpecialCharacters(strings):
    pattern = "[^a-zA-Z0-9_]"
    return re.sub(pattern, "", strings)

def getProtoName(line):
    idx = line.find("S2C")
    if idx > 0 :
        return removeSpecialCharacters(line[idx:])
    else :
        idx = line.find("C2S")
        if idx > 0 :
            return removeSpecialCharacters(line[idx:])

def initProtoDict():
    if os.path.exists(protoFile):
        fo = open(protoFile, "r")
        lines = fo.readlines()
        for line in lines:
            idx = line.index(line.lstrip())
            if idx > 0 :
                endIdx = line.find(" ", idx)
                protoName = line[idx:endIdx]
                curId = int(line[line.rfind("=") + 1:line.rfind(",")])
                protoDict[protoName] = curId
                protoIdDict[curId] = protoName
                global protoId
                if curId > protoId:
                    protoId = curId
    for i in range(1, protoId):
        if not protoIdDict.get(i):
            availableIdList.append(i)
        
def writeProtoDict():
    if not os.path.exists(protoFile):
        open(protoFile, "w").close()
    fo = open(protoFile, "r+")
    fo.write("return {\n")
    sortedDict = sorted(protoDict.items(), key=lambda x: x[1])
    for key, value in sortedDict:
        fo.write("    {} = {},\n".format(key, value))
    fo.write("}")

def genProtoDict():
    for root, dirs, files in os.walk(".", topdown=False):
        for name in files:
            filePath = os.path.join(root, name)
            if filePath.count(".proto") > 0 :
                fo = open(filePath, "r")
                lines = fo.readlines()
                for line in lines:
                    if line.find("message") >= 0 :
                        protoName = getProtoName(line)
                        if protoName :
                            if not protoDict.get(protoName):
                                protoDict[protoName] = getProtoId(protoName)
def main():
    initProtoDict()
    genProtoDict()
    writeProtoDict()
main()