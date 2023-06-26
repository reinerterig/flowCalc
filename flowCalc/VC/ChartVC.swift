//
//  ChartVC.swift
//  flowCalc
//
//  Created by reinert wasserman on 23/6/2023.
//

import UIKit
import AcaiaSDK
import SwiftUI
import DGCharts
import TinyConstraints
import CSV
import FirebaseStorage

class ChartVC: UIViewController {
    var weightData: [ChartDataEntry] = []
    var smoothedFlowData: [ChartDataEntry] = []
    var smoothedFlowRate: Double = 0
    var timer: Timer!
    var count: Double = 0
    var newWeight: Double = Double(scaleWeight)!
    var oldtWeight: Double = 0
    var flowWeight: Double = 0
    var flowArray: [Double] = []
    var chartMode: Bool = false
    var isRunning: Bool = false
    let uploadRef = Storage.storage().reference()
    
    @IBOutlet weak var StartStop: UIButton!
    
    lazy var lineChart: LineChartView = {
        let chartView = LineChartView()
        return chartView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        createLineChart()
        StartStop.setTitle("Start", for: UIControl.State.normal)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
      
    }
    
    
    
    override func viewWillDisappear(_ animated: Bool) {
        if isRunning == true {
            timer?.invalidate()
            timer = nil
            print("Timer Stopped")
        }
    }
    override func viewDidDisappear(_ animated: Bool) {
        weightData.removeAll()
        
        
    }
    
    func createTimer(){
        timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(counter), userInfo: nil, repeats: true)
        isRunning = true
        
    }
    
    @objc func counter(){
       //counts up in miliseconds and formats the count to a "clock" time
        count += 0.1
        let minutes = Int(count) / 60 % 60
        let seconds = Int(count) % 60
        let mil = Int(count*10) % 10
        let m_s = String(format:"%02i.%02i%01i", minutes, seconds,mil)
        
        // every tick append update the chart with new time and weight entry
        let weightDataEntry = ChartDataEntry(x: Double(m_s) ?? 0, y: Double(scaleWeight) ?? 0)
        self.weightData.append(weightDataEntry)
        
        // MARK: wight to flow
        createFlowChart()
        // every tick append update the chart with new time and flow entry
        
        
        // every tick append update the chart with new time and smoothed flow entry
        let smoothedFlowDataEntry = ChartDataEntry(x: Double(m_s) ?? 0, y: smoothedFlowRate)
            self.smoothedFlowData.append(smoothedFlowDataEntry)
        
        self.updateChart(wdata: self.weightData, fdata: self.smoothedFlowData)
       
    }
    
    //MARK: Smooth Flow
    // converts weight data to flow also smoothes flow data
    func createFlowChart(){
        newWeight = Double(scaleWeight) ?? 0
        flowWeight = newWeight - oldtWeight
        flowArray.append(flowWeight)
        
        let windowSize = 10
        let smoothedFlowArray: [Double]
        
        if flowArray.count <= windowSize {
                smoothedFlowArray = flowArray
          } else {
              let startIndex = flowArray.count - windowSize
              let endIndex = flowArray.count
              smoothedFlowArray = Array(flowArray[startIndex..<endIndex])
          }
        
           smoothedFlowRate = smoothedFlowArray.reduce(0, { x, y in x + y }) / Double(smoothedFlowArray.count)
        print("flow: ", flowWeight, " Smoothed: ", smoothedFlowRate)
            oldtWeight = newWeight
    }
    
    
    //MARK: create linechart
    //set chart style
    func createLineChart(){
        view.addSubview(lineChart)
        lineChart.translatesAutoresizingMaskIntoConstraints = false
        lineChart.centerInSuperview()
        NSLayoutConstraint.activate([
            lineChart.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            lineChart.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            ])
        
        
        let yAxis = lineChart.leftAxis
        lineChart.backgroundColor = UIColor.systemRed.withAlphaComponent(0.1)
        lineChart.rightAxis.enabled = false
        yAxis.labelPosition = .insideChart
    }

//MARK: Fill data into chart
//set line style
    func updateChart(wdata: [ChartDataEntry],fdata: [ChartDataEntry] ) {
            let wDataSet = LineChartDataSet(entries: wdata, label: "Espresso Weight")
            let wData = LineChartData(dataSet: wDataSet)
        
            let fDataSet = LineChartDataSet(entries: fdata, label: "Espresso flow")
            let fData = LineChartData(dataSet: fDataSet)

            // Customize the line chart here if you want.
            // For example:
            wDataSet.colors = [UIColor.red]
            wDataSet.circleColors = [UIColor.red]
            wDataSet.drawCirclesEnabled = false
            wDataSet.mode = .cubicBezier
        // could all of this be cleaner?
            fDataSet.colors = [UIColor.blue]
            fDataSet.circleColors = [UIColor.red]
            fDataSet.drawCirclesEnabled = false
            fDataSet.mode = .cubicBezier
            
        if chartMode == true{
            lineChart.data = wData
            wData.setDrawValues(false)
            lineChart.setNeedsDisplay()
        } else if chartMode == false{
            lineChart.data = fData
            fData.setDrawValues(false)
            lineChart.setNeedsDisplay()
        }
    }
    
    
    // Start and pause timer
    @IBAction func onBtnStop(_ sender: UIButton) {
        if isRunning == true {
            timer?.invalidate()
            timer = nil
            StartStop.setTitle("Stop", for: UIControl.State.normal)
            isRunning = false
            print("Timer Stopped")
            
        } else if isRunning == false && AcaiaManager.shared().connectedScale != nil{
            createTimer()
            isRunning = true
            print("Timer Started")
            StartStop.setTitle("Start", for: UIControl.State.normal)
        }
    }
    
    // toggle between flow & weight chart
    @IBAction func toggleView(_ sender: UIButton) {
        if chartMode == true {
            chartMode = false
            self.updateChart(wdata: self.weightData, fdata: self.smoothedFlowData)
        } else {
            chartMode = true
            self.updateChart(wdata: self.weightData, fdata: self.smoothedFlowData)
        }
    }
    
    // test for creating file and uploading
    @IBAction func onUpload(_ sender: UIButton) {
        createCSV()
    }
    
    func createCSV(){
        do {
            
            // Timestamp
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyyMMdd-HHmm"
            let timestamp = formatter.string(from: Date())
            
            // Weight Data
            let weightFileName = "\(timestamp)-WeightData"
            let weightDocumentDirURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            let weightFileURL = weightDocumentDirURL.appendingPathComponent(weightFileName).appendingPathExtension("csv")
            
            let weightStream = OutputStream(url: weightFileURL, append: false)!
            let weightCSVWriter = try CSVWriter(stream: weightStream)
            for data in weightData {
                try weightCSVWriter.write(row: ["\(data.x)", "\(data.y)"])
            }
            weightCSVWriter.stream.close()
            
            // Smoothed Flow Data
            let flowFileName = "\(timestamp)-SmoothedFlowData"
            let flowDocumentDirURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            let flowFileURL = flowDocumentDirURL.appendingPathComponent(flowFileName).appendingPathExtension("csv")
            
            let flowStream = OutputStream(url: flowFileURL, append: false)!
            let flowCSVWriter = try CSVWriter(stream: flowStream)
            for data in smoothedFlowData {
                try flowCSVWriter.write(row: ["\(data.x)", "\(data.y)"])
            }
            flowCSVWriter.stream.close()
            
            // Upload CSVs
            uploadCSV(timestamp: timestamp,weightCSV: weightFileURL, flowCSV: flowFileURL)
        } catch {
            print("Error creating CSV files: \(error)")
        }
    }

    func uploadCSV(timestamp: String,weightCSV: URL, flowCSV: URL){
        let folderName = "\(timestamp)-ChartData"
        
        let weightStorageRef = uploadRef.child("flowCalc/ChartData/\(folderName)/\(timestamp)-WeightData.csv")
        let weightUploadTask = weightStorageRef.putFile(from: weightCSV)
        
        let flowStorageRef = uploadRef.child("flowCalc/ChartData/\(folderName)/\(timestamp)-SmoothedFlowData.csv")
        let flowUploadTask = flowStorageRef.putFile(from: flowCSV)
    }

}

