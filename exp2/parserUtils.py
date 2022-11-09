#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import collections

def readGrammar(filePath):
  grammar = collections.defaultdict(list)
  with open(filePath, 'r') as f:
    # 按行读取，加入文法字典
    for line in f:
      pre, post = line.rstrip('\n').split('->')
      pre = pre.rstrip(' ')
      post = post.lstrip(' ').split('|')

      for eachpost in post:
        eachpost = eachpost.strip(' ').split(' ')
        grammar[pre].append(eachpost)

  return grammar


def differentiateSymbols(grammar):
  terminal = []
  nonTerminal = []
  tempSymbols = []

  for eachpre in grammar:
    if eachpre not in nonTerminal:
      nonTerminal.append(eachpre)

    postList = grammar[eachpre]
    for eachpost in postList:
      for eachpostItem in eachpost:
        tempSymbols.append(eachpostItem)

  for eachTempSymbol in tempSymbols:
    if eachTempSymbol not in nonTerminal and eachTempSymbol not in terminal:
      terminal.append(eachTempSymbol)

  terminal.append('#')
  if 'ε' in terminal:
    terminal.remove('ε')
  return terminal, nonTerminal


def getFIRST(firstSet, grammar, terminal, nonTerminal):
  for eachGrammar in grammar:
    for eachpost in grammar[eachGrammar]:

      if eachpost[0] in terminal:
        if not eachpost[0] in firstSet[eachGrammar]:
          firstSet[eachGrammar].append(eachpost[0])

      elif eachpost[0] == 'ε':
        if not eachpost[0] in firstSet[eachGrammar]:
          firstSet[eachGrammar].append(eachpost[0])

      else:
        for eachpostItem in eachpost:
          if eachpostItem in terminal:
            if not eachpostItem in firstSet[eachGrammar]:
              firstSet[eachGrammar].append(eachpostItem)
            break

          elif 'ε' in firstSet[eachpostItem]:
            for item in firstSet[eachpostItem]:
              if not item in firstSet[eachGrammar]:
                firstSet[eachGrammar].append(item)

          else:
            for item in firstSet[eachpostItem]:
              if not item in firstSet[eachGrammar]:
                firstSet[eachGrammar].append(item)
            break

  return firstSet


def getFOLLOW(firstSet, followSet, grammar, terminal, nonTerminal):
  for eachStart in grammar.keys():
    for eachGrammar in grammar:
      for eachpost in grammar[eachGrammar]:
        if eachStart in eachpost:
          index = eachpost.index(eachStart)
          lastItemIndex = len(eachpost) - 1
          if index == lastItemIndex:
            for item in followSet[eachGrammar]:
              if not item in followSet[eachStart]:
                followSet[eachStart].append(item)
          else:
            if eachpost[index + 1] in terminal:
              if not eachpost[index + 1] in followSet[eachStart]:
                followSet[eachStart].append(
                    eachpost[index + 1])
            else:
              for i in range(index + 1, lastItemIndex + 1):
                if eachpost[i] in terminal:
                  if not eachpost[i] in followSet[eachStart]:
                    followSet[eachStart].append(
                        eachpost[i])
                  break
                elif 'ε' in firstSet[eachpost[i]]:
                  for item in firstSet[eachpost[i]]:
                    if not item in followSet[eachStart] and item != 'ε':
                      followSet[eachStart].append(item)
                  if i == lastItemIndex:
                    for item in followSet[eachGrammar]:
                      if not item in followSet[eachStart]:
                        followSet[eachStart].append(item)
                else:
                  for item in firstSet[eachpost[i]]:
                    if not item in followSet[eachStart] and item != 'ε':
                      followSet[eachStart].append(item)
                  break

  return followSet


def getRuleFirstSet(preRule, postRule, terminal, nonTerminal, firstSet):
  ruleFirstSet = []
  for eachRule in postRule:
    if eachRule in terminal:
      if not eachRule in ruleFirstSet:
        ruleFirstSet.append(eachRule)
      break
    elif eachRule == 'ε':
      if not eachRule in ruleFirstSet:
        ruleFirstSet.append(eachRule)
      break
    else:
      if eachRule in terminal:
        if not eachRule in ruleFirstSet:
          ruleFirstSet.append(eachRule)
        break
      elif 'ε' in firstSet[eachRule]:
        for item in firstSet[eachRule]:
          if not item in ruleFirstSet:
            ruleFirstSet.append(item)
      else:
        for item in firstSet[eachRule]:
          if not item in ruleFirstSet:
            ruleFirstSet.append(item)
        break
  return ruleFirstSet


def createAnalyzeTable(grammar, terminal, nonTerminal, firstSet, followSet):

  analyzeTable = collections.defaultdict(dict)

  for eachGrammar in grammar:
    for eachpost in grammar[eachGrammar]:
      postFirstSet = getRuleFirstSet(eachGrammar, eachpost, terminal, nonTerminal, firstSet)

      for eachTerminalSymbol in terminal:
        if eachTerminalSymbol in postFirstSet:
          analyzeTable[eachGrammar].update({eachTerminalSymbol: eachpost})

      if 'ε' in postFirstSet:
        for eachTerminalSymbol in terminal:
          if eachTerminalSymbol in followSet[eachGrammar]:
            analyzeTable[eachGrammar].update({eachTerminalSymbol: eachpost})

  return analyzeTable
