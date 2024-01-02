# -*- coding: utf-8 -*-
import xlrd
import xlwt
from xlrd import open_workbook
import os
import math

inputDir = "./"
outputDir = "./../../src/etc/cfg"
def readExecl():
    return 1
    
import xlrd

def getCellData(sheets, row, col):
    for merged_cell in sheets.merged_cells:
        start_row, end_row, start_column, end_colum = merged_cell[0], merged_cell[1], merged_cell[2], merged_cell[3]
        if start_row <= row and row < end_row and start_column <= col and col < end_colum:
            cell = sheets.cell(start_row, start_column)
            cellValue = cell.value
            return cellValue, True
    cell = sheets.cell(row, col)
    cellValue = cell.value
    return cellValue, False

def main():
    sheetFileDict = {}
    for root,dirs,files in os.walk(inputDir):
        for dirname in dirs:
            for outputFormat in outputFormats:
                os.makedirs(os.path.join(outputDir,outputFormat,dirname))
        for fileName in files:
            if fileName.find("xlsx") >= 0 or fileName.find("xls") >= 0:
                sheetFileDict[fileName] = os.path.join(root, fileName)
    sheetRet = {}
    for fileName, filePath in sheetFileDict.items():
        print(fileName, filePath)
        sheetRet[fileName] = {}
        workBook = xlrd.open_workbook(filePath, formatting_info=True)
        for sheets in workBook.sheets():        # 所有表
            ns = sheets.nrows
            maxMergeLevel = 1
            for row in range(ns):     # 第几行
                cs = sheets.ncols
                for col in range(cs): # 第几列
                    if row > 3:
                        cellValue, isMerge = getCellData(sheets, row, col)
                        if isMerge:
                            if maxMergeLevel < col + 1:
                                maxMergeLevel = col + 1
                        else:
                            break
            explanatory = {}
            keys = {}
            dataTypes = {}
            data = {}
            for row in range(sheets.nrows):     # 第几行
                tagTbl = data
                tblData = {}
                for col in range(sheets.ncols): # 第几列
                    cellValue, isMerge = getCellData(sheets, row, col)
                    if row == 0:
                        explanatory[col] = cellValue
                    elif row == 1:
                        keys[col] = cellValue
                    elif row == 2:
                        dataTypes[col] = cellValue
                    elif row > 3:
                        key = keys[col]
                        if cellValue:
                            if dataTypes[col] == "int32":
                                tblData[key] = int(cellValue)
                            elif dataTypes[col] == "string":
                                tblData[key] = cellValue
                            if col < maxMergeLevel:
                                if not tagTbl.get(cellValue):
                                    tagTbl[cellValue] = {}
                                tagTbl = tagTbl[cellValue]
                if len(tblData) > 0:
                    for key, value in tblData.items():
                        tagTbl[key] = value
            luaFileName = fileName[:fileName.find(".")] + ".lua"
            with open(luaFileName, 'w', encoding='utf-8') as file:
                file.write("local data = {\n")
                if maxMergeLevel == 1:
                    for key1, value1 in data.items():
                        file.write("\t[" + str(math.floor(key1)) + "] = {\n")
                        for key4, value4 in value1.items():
                            if type(value4) == str :
                                file.write("\t\t" + key4 + " = \"" + value4 +"\",\n")
                            else:
                                file.write("\t\t" + key4 + " = " + str(value4) +",\n")
                        file.write("\t},\n")
                elif maxMergeLevel == 2:
                    for key1, value1 in data.items():
                        file.write("\t[" + str(math.floor(key1)) + "] = {\n")
                        for key2, value2 in value1.items():
                            file.write("\t\t[" + str(math.floor(key2)) + "] = {\n")
                            for key4, value4 in value2.items():
                                if type(value4) == str :
                                    file.write("\t\t\t" + key4 + " = \"" + value4 +"\",\n")
                                else:
                                    file.write("\t\t\t" + key4 + " = " + str(value4) +",\n")
                            file.write("\t\t},\n")
                        file.write("\t},\n")
                elif maxMergeLevel == 3:
                    for key1, value1 in data.items():
                        file.write("\t[" + str(math.floor(key1)) + "] = {\n")
                        for key2, value2 in value1.items():
                            file.write("\t\t[" + str(math.floor(key2)) + "] = {\n")
                            for key3, value3 in value2.items():
                                file.write("\t\t\t[" + str(math.floor(key3)) + "] = {\n")
                                for key4, value4 in value3.items():
                                    if type(value4) == str :
                                        file.write("\t\t\t\t" + key4 + " = \"" + value4 +"\",\n")
                                    else:
                                        file.write("\t\t\t\t" + key4 + " = " + str(value4) +",\n")
                                file.write("\t\t\t},\n")
                            file.write("\t\t},\n")
                        file.write("\t},\n")
                file.write("}")
main()