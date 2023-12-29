import xlrd
import xlwt
from xlrd import open_workbook
import os

inputDir = "./"
outputDir = "./../../src/etc/cfg"
def readExecl():
    return 1
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
        workBook = xlrd.open_workbook(filePath)
        for sheets in workBook.sheets():        # 所有表
            maxMergeLevel = 1
            ns = sheets.nrows
            for row in range(ns):     # 第几行
                cs = sheets.ncols
                sstin = ""
                for col in range(cs): # 第几列
                    sheetData = sheets.cell(row, col).value  #sheets[row][col]
                    sstin = sstin + "\t" + str(sheetData)
                print(sstin)
            for row in range(ns):     # 第几行
                isMerge = False
                cs = sheets.ncols
                for col in range(cs): # 第几列
                    if row > 3:
                        sheetData = sheets.cell(row, col).value  #sheets[row][col]
                        lastRowSheetData = None
                        print(row, col)
                        if row - 1 >= 0:
                            lastRowSheetData = sheets.cell(row - 1, col).value
                        if not isMerge and lastRowSheetData and lastRowSheetData == sheetData:
                            isMerge = True
                            print(row, col, "isMerge", row - 1, col)
                        nextRowSheetData = None
                        if row + 1 <= ns:
                            nextRowSheetData = sheets.cell(row + 1, col).value
                        if not isMerge and nextRowSheetData and nextRowSheetData == sheetData:
                            isMerge = True
                            print(row, col, "isMerge", row + 1, col)
                        print()
                        if isMerge:
                            if maxMergeLevel < col + 1:
                                maxMergeLevel = col + 1
                        else:
                            break
            print(maxMergeLevel)
        # for sheets in workBook.sheets():        # 所有表
        #     explanatory = {}
        #     ids = {}
        #     dataTypes = {}
        #     data = {}
        #     for row in range(sheets.nrows):     # 第几行
        #         colId = sheets.cell(row, 0).value
        #         isMerge = False
        #         for col in range(sheets.ncols): # 第几列
        #             if row == 0:
        #                     explanatory[col] = sheetData
        #             elif row == 1:
        #                     ids[col] = sheetData
        #             elif row == 2:
        #                     dataTypes[col] = sheetData
        #             elif row == 3:
        #                     if type(sheetData) == "sting":
        #                         print()
        #             else:
        #     for key, values in data.items():
        #         st = ""
        #         for id, value in values.items():
        #             st = st + " " + str(value)
        #         print(st)
main()