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

class ChartVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
    var weightData: [ChartDataEntry] = []
    var smoothedFlowData: [ChartDataEntry] = []
    var loadedWeightData: [ChartDataEntry] = []
    var loadedSmoothedFlowData: [ChartDataEntry] = []
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
    var tableViewHeight: CGFloat!
    var menuView: UIView!
    var initialTouchPoint = CGPoint.zero
    var sideTableView: UITableView!
    let numberOfRowsInMenu: Int = 3
    let menuViewTag: Int = 100  // Arbitrary number, just make sure it's unique in your view hierarchy
    let sideTableViewTag: Int = 101  // Arbitrary number, just make sure it's unique in your view hierarchy
    var numberOfRowsInSideTable: Int = 20  // This can be any number you want
    var folderList: [String] = []
    
    
    
    @IBOutlet weak var StartStop: UIButton!
    
    lazy var lineChart: LineChartView = {
        let chartView = LineChartView()
        return chartView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        createLineChart()
        StartStop.setTitle("Start", for: UIControl.State.normal)
        listStorage()
        
        // Add long press gesture
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
        longPressGesture.minimumPressDuration = 0.2 // Long press duration of one second
        self.view.addGestureRecognizer(longPressGesture)
        
        
        
        
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
    
    func listStorage(){
        let storage = Storage.storage()
        let storageReference = storage.reference().child("flowCalc/ChartData")
        storageReference.listAll { (result, error) in
            if let error = error {
                // Handle the error
                print("Error: \(error)")
            } else {
                // Iterate over the prefixes (folders)
                for prefix in result!.prefixes {
                    let folderName = prefix.fullPath.components(separatedBy: "/").last!
                    print(folderName)
                    self.folderList.append(folderName)
                    self.numberOfRowsInSideTable = self.folderList.count
                }
                // Iterate over the items (files)
                for item in result!.items {
                    let itemName = item.fullPath.components(separatedBy: "/").last!
                    print(itemName)
                }
            }
        }
    }



    @objc func handleLongPress(gesture: UILongPressGestureRecognizer){
        initialTouchPoint = gesture.location(in: view)
        if gesture.state == .began {
            // Remove any existing menu view
            self.view.viewWithTag(menuViewTag)?.removeFromSuperview()
            self.view.viewWithTag(sideTableViewTag)?.removeFromSuperview()
            
            // Calculate the height of the table view
            let rowHeight: CGFloat = 44.0
            tableViewHeight = rowHeight * CGFloat(numberOfRowsInMenu)
            
            // Get the location of the long press
            let longPressLocation = gesture.location(in: self.view)
            
            // Create the subview
            let menuView = UIView()
            menuView.frame = CGRect(x: longPressLocation.x, y: longPressLocation.y, width: 200, height: tableViewHeight)
            menuView.backgroundColor = .white
            menuView.tag = menuViewTag  // Set the tag
            
            let tableView = UITableView()
            tableView.frame = menuView.bounds
            tableView.dataSource = self
            tableView.delegate = self
            tableView.rowHeight = rowHeight
            tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
            
            menuView.addSubview(tableView)
            self.view.addSubview(menuView)
        }
    }
    
    
    
    func createSideTableView() {
        // Remove any existing side table view
        self.view.viewWithTag(sideTableViewTag)?.removeFromSuperview()
        
        // Create the subview
        let sideView = UIView()
        sideView.frame = CGRect(x: self.view.bounds.midX, y: 0, width: self.view.bounds.midX, height: self.view.bounds.height)
        sideView.backgroundColor = .white
        sideView.tag = sideTableViewTag  // Set the tag
        
        // Create the table view
        sideTableView = UITableView()
        sideTableView.frame = sideView.bounds
        sideTableView.dataSource = self
        sideTableView.delegate = self
        sideTableView.rowHeight = 44.0
        sideTableView.register(UITableViewCell.self, forCellReuseIdentifier: "sideCell")
        
        // Add the table view to the subview
        sideView.addSubview(sideTableView)
        
        // Add the subview to the main view
        self.view.addSubview(sideView)
        
        // Animate the view onto the screen from the right
        sideView.frame.origin.x = self.view.bounds.width
        UIView.animate(withDuration: 0.25) {
            sideView.frame.origin.x = self.view.bounds.midX
        }
    }
    
    
    
    // UITableViewDataSource methods
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == sideTableView {
            return numberOfRowsInSideTable
        }
        return 3
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == sideTableView {
            let cell = tableView.dequeueReusableCell(withIdentifier: "sideCell", for: indexPath)
            if indexPath.row < folderList.count {
                cell.textLabel?.text = folderList[indexPath.row]
            } else {
                cell.textLabel?.text = "Row \(indexPath.row)"  // Fallback, just in case
            }
            return cell
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        switch indexPath.row {
        case 0:
            cell.textLabel?.text = "Upload"
        case 1:
            cell.textLabel?.text = "Toggle"
        case 2:
            cell.textLabel?.text = "Saved Charts"
        default:
            break
        }
        return cell
    }
    
    
    // UITableViewDelegate method
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        self.view.viewWithTag(menuViewTag)?.removeFromSuperview()
        self.view.viewWithTag(sideTableViewTag)?.removeFromSuperview()
        if tableView == sideTableView {
            print(folderList[indexPath.row], "has been pressed")
            self.view.viewWithTag(sideTableViewTag)?.removeFromSuperview()
            return
        }
        switch indexPath.row {
        case 0:
            //Upload
            createCSV()
        case 1:
            //Toggle
            if chartMode == true {
                chartMode = false
                self.updateChart(wdata: self.weightData, fdata: self.smoothedFlowData)
            } else {
                chartMode = true
                self.updateChart(wdata: self.weightData, fdata: self.smoothedFlowData)
            }
        case 2:
            createSideTableView()
            print("Start / Stop Pressed")
        default:
            break
        }
        self.view.viewWithTag(menuViewTag)?.removeFromSuperview()
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






