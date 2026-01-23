//
//  main.swift
//  com.metacubex.Neko.ProxyConfigHelper


import Foundation

ProcessInfo.processInfo.disableSuddenTermination()
let helper = ProxyConfigHelper()
helper.run()

print("ProxyConfigHelper exit")
