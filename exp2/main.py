#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import collections
import copy
import os
import xml.etree.ElementTree as ET
from anytree import RenderTree
from anytree.exporter import DictExporter
from dicttoxml import dicttoxml
from xml.dom.minidom import parseString

import scan
import parserUtils
import parserGeneral


def readToken(filePath):
  """
  读入 Token XML 中的内容
  """
  inputTokenList = []

  tokenRoot = ET.parse(filePath).getroot()
  tokens = tokenRoot[0]
  for i in range(0, len(tokens)):
    inputTokenList.append(tokens[i])
  return inputTokenList


def main():
  print('[INFO] Start parsing...')

  # 文法文件路径
  grammarFile = 'grammar.txt'
  scan.lex_scan()

  # 1. 读入文法
  grammar = parserUtils.readGrammar(grammarFile)

  # 2. 划分终结符与非终结符
  terminalSymbols, nonTerminalSymbols = parserUtils.differentiateSymbols(
      grammar)

  # 3-1. 递归求 FIRST 集
  firstSet = collections.defaultdict(list)
  firstSet = parserUtils.getFIRST(
      firstSet, grammar, terminalSymbols, nonTerminalSymbols)
  while True:
    originalFirst = copy.deepcopy(firstSet)
    firstSet = parserUtils.getFIRST(
        firstSet, grammar, terminalSymbols, nonTerminalSymbols)
    if firstSet == originalFirst:
      break
  
  print('[FIRST SET]:')
  for item in firstSet.items():
    print(' ', item)

  # 3-2. 递归求 FOLLOW 集
  grammarTop = list(grammar.keys())[0]
  followSet = collections.defaultdict(list, {grammarTop: ['#']})

  followSet = parserUtils.getFOLLOW(
      firstSet, followSet, grammar, terminalSymbols, nonTerminalSymbols)
  while True:
    originalFollow = copy.deepcopy(followSet)
    followSet = parserUtils.getFOLLOW(
        firstSet, followSet, grammar, terminalSymbols, nonTerminalSymbols)
    if followSet == originalFollow:
      break

  print('[FOLLOW SET]:')
  for item in followSet.items():
    print(' ', item)

  # 4. 创建 LL1 分析表
  analyzeTable = parserUtils.createAnalyzeTable(
      grammar, terminalSymbols, nonTerminalSymbols, firstSet, followSet)
  print('[ANALYZE TABLE]:')
  for item in analyzeTable.items():
    print(' ', item)
  with open('analyze_table.csv', 'w') as f:
    print(type(f))
    [f.write('{0},{1}\n'.format(key, value)) for key, value in analyzeTable.items()]

  # 分析输入 Token 文件
  tokenFile = os.path.join('test', 'input.token.xml')
  print("[ANALYZE STACK]")
  tokenList = readToken(tokenFile)
  tree = parserGeneral.parseToken(
      tokenList, grammar, terminalSymbols, nonTerminalSymbols, analyzeTable)

  exporter = DictExporter(dictcls=collections.OrderedDict, attriter=sorted)
  exportDict = exporter.export(tree)
  xml = parseString(dicttoxml(exportDict, attr_type=False))
  xml = xml.toprettyxml(indent='  ', encoding='utf-8')


if __name__ == "__main__":
  main()
