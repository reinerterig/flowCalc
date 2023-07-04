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



class ChartVC: UIViewController, UITableViewDelegate, UITableViewDataSource,ChartViewDelegate {
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
    let storage = Storage.storage()
    var folderList: [String] = []
    var folderPath: [StorageReference] = []
    var CSVpath: [StorageReference] = []
    var CSVname: [String] = []
    var receivedImage: UIImage?
    var dose: String      = String(Recipy.pre.dose  ?? 0)
    var grindSize:String  = String(Recipy.pre.grindSize ?? 0)
    var rpm: String       = String(Recipy.pre.rpm  ?? 0)
    var preWet:String     = String(Recipy.pre.preWet ?? false)
    var body: String      = String(Recipy.post.body ?? 0)
    var Acidity: String   = String(Recipy.post.aciduty ?? 0)
    var Sweetness: String = String(Recipy.post.sweetness ?? 0)
    var Bitterness: String = String(Recipy.post.bitterness ?? 0)
    var Rating: String    = String(Recipy.post.rating ?? 0)
    

    @IBOutlet weak var StartStop: UIButton!
    
    lazy var lineChart: LineChartView = {
        let chartView = LineChartView()
        return chartView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.overrideUserInterfaceStyle = .dark
        createLineChart()
        StartStop.setTitle("Start", for: UIControl.State.normal)
        listStorage(ref: storage.reference().child("flowCalc/ChartData"))
        
        // Add long press gesture
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
        longPressGesture.minimumPressDuration = 0.2 // Long press duration of one second
        self.view.addGestureRecognizer(longPressGesture)
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        
        let delegate = UIApplication.shared.delegate as! AppDelegate
        delegate.orientationLock = .landscape
        
    }
    
    
    
    override func viewWillDisappear(_ animated: Bool) {
        
    }
    override func viewDidDisappear(_ animated: Bool) {
        let delegate = UIApplication.shared.delegate as! AppDelegate
        delegate.orientationLock = .all
        
    }
    
    //MARK: List Storage
    func listStorage(ref: StorageReference){
        let storageReference = ref
//        self.weightData.removeAll()
//        self.smoothedFlowData.removeAll()
        
        
        storageReference.listAll { (result, error) in
            if let error = error {
                // Handle the error
                print("Error: \(error)")
            } else {
                // Iterate over the prefixes (folders)
                for prefix in result!.prefixes {
                    let folderName = prefix.fullPath.components(separatedBy: "/").last!
                    
                    self.folderList.append(folderName)
                    self.folderPath.append(prefix)
                    self.numberOfRowsInSideTable = self.folderList.count
                }
                // Iterate over the items (files)
                for itempath in result!.items {
                    let fullItemName = itempath.fullPath.components(separatedBy: "/").last!
                    let itemName = fullItemName.components(separatedBy: "-")[2...].joined(separator: "-")
                    

                    switch String(itemName){
                    case "SmoothedFlowData.csv", "WeightData.csv","preShotData.csv"://,"postShotData.csv":
                        print(fullItemName)
                        print("")
                        let CsvRef = itempath
                        let FileName =  fullItemName
                        print(CsvRef)
                        print("")
                        let DocumentDirURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                        let FileURL = DocumentDirURL.appendingPathComponent(FileName)
                        CsvRef.write(toFile: FileURL){ url, error in
                            if let error = error {
                                
                            } else {
                            }
                        }
                        
                        let fileManager = FileManager.default
                        
                        if fileManager.fileExists(atPath: FileURL.path) {
                            print(itemName, ": File was created successfully")
                            print("")
                        } else {
                            print(itemName, ": Failed to create the file")
                            print("")
                        }
                        
                        
                        let stream = InputStream(url: FileURL)!
                        
                        
                        let csv = try! CSVReader(stream: stream)
                        
                        switch String(itemName){
                        case "SmoothedFlowData.csv", "WeightData.csv":
                            
                            while let row = csv.next() {
                                
                                let x = String(row.first ?? "0")
                                let y = String(row.last ?? "0")
                                self.CsvToChart(tp:String(itemName),dx: Double(x) ?? 0,dy: Double(y) ?? 0 )
                                
                            }
                        case "preShotData.csv":
                            while let row = csv.next() {
                                switch row.first {
                                case "dose":
                                    Recipy.pre.dose = Double(row.last!)
                                case "grindSize":
                                    Recipy.pre.grindSize = Double(row.last!)
                                case "rpm":
                                    Recipy.pre.rpm = Double(row.last!)
                                case "preWet":
                                    Recipy.pre.preWet = Bool(row.last!)
                                default:
                                    return
                                }
                            }
                        case "postShotData.csv":
                            while let row = csv.next() {
                                switch row.first {
                                case "Body":
                                    Recipy.post.body = Double(row.last!)
                                case "Acidity":
                                    Recipy.post.aciduty = Double(row.last!)
                                case "Sweetness":
                                    Recipy.post.sweetness = Double(row.last!)
                                case "Bitterness":
                                    Recipy.post.bitterness = Double(row.last!)
                                case "Rating":
                                    Recipy.post.rating = Double(row.last!)
                                default:
                                    return
                                }
                            }
                            
                        default:
                            return
                        }
                    case "Tamp.jpg":
                        print("")
                        itempath.getData(maxSize: 1 * 1024 * 1024) { data, error in
                            if let error = error {
                              // Uh-oh, an error occurred!
                            } else {
                              // Data for "images/island.jpg" is returned
                              let receivedImage = UIImage(data: data!)
                            }
                          }
                    default:
                        return
                    }
                }
            }
        }
    }
    //MARK: Upload
    func uploadCSV(timestamp: String,weightCSV: URL, flowCSV: URL, preShotCSV: URL, postShotCSV: URL){
        let folderName = "\(timestamp)-ChartData"
        if tampImage != nil {
            let imgRef = uploadRef.child("flowCalc/ChartData/\(folderName)/\(timestamp)-Tamp.jpg")
            let imgData = tampImage!.jpegData(compressionQuality: 0.8)
            
            _ = imgRef.putData(imgData!) { metadata, error in
                if error == nil && metadata != nil {
                }
            }
        }
        
        let preShotStorageRef = uploadRef.child("flowCalc/ChartData/\(folderName)/\(timestamp)-preShotData.csv")
        _ = preShotStorageRef.putFile(from: preShotCSV)
        
        let postShotStorageRef = uploadRef.child("flowCalc/ChartData/\(folderName)/\(timestamp)-postShotData.csv")
        _ = postShotStorageRef.putFile(from: postShotCSV)
        
        let weightStorageRef = uploadRef.child("flowCalc/ChartData/\(folderName)/\(timestamp)-WeightData.csv")
        _ = weightStorageRef.putFile(from: weightCSV)
        
        let flowStorageRef = uploadRef.child("flowCalc/ChartData/\(folderName)/\(timestamp)-SmoothedFlowData.csv")
        _ = flowStorageRef.putFile(from: flowCSV)
    }
    
    // load saved chart and update display
    func CsvToChart(tp: String,dx: Double, dy: Double){
        
        if tp == "SmoothedFlowData.csv" {
            
            ChartData.shared.smoothedFlowData.append(ChartDataEntry(x: dx, y: dy))
        } else if tp == "WeightData.csv" {
            
            ChartData.shared.weightData.append(ChartDataEntry(x: dx, y: dy))
        }
        updateChart(wdata: ChartData.shared.weightData, fdata: ChartData.shared.smoothedFlowData)
        
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
            let selectedFolder = folderPath[indexPath.row]
            
            //MARK: Download
            
            listStorage(ref: selectedFolder)
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
                self.updateChart(wdata: ChartData.shared.weightData, fdata: ChartData.shared.smoothedFlowData)
            } else {
                chartMode = true
                self.updateChart(wdata: ChartData.shared.weightData, fdata: ChartData.shared.smoothedFlowData)
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
        ChartData.shared.weightData.append(weightDataEntry)
        
        // MARK: wight to flow
        createFlowChart()
        // every tick append update the chart with new time and flow entry
        
        
        // every tick append update the chart with new time and smoothed flow entry
        let smoothedFlowDataEntry = ChartDataEntry(x: Double(m_s) ?? 0, y: smoothedFlowRate)
        ChartData.shared.smoothedFlowData.append(smoothedFlowDataEntry)
        
        self.updateChart(wdata: ChartData.shared.weightData, fdata: ChartData.shared.smoothedFlowData)
        
    }
    
    //MARK: Smooth Flow
    // converts weight data to flow also smoothes flow data
    func createFlowChart(){
        newWeight = Double(scaleWeight) ?? 0
        flowWeight = newWeight - oldtWeight
        flowArray.append(flowWeight)
        
        let windowSize = 20
        let smoothedFlowArray: [Double]
        
        if flowArray.count <= windowSize {
            smoothedFlowArray = flowArray
        } else {
            let startIndex = flowArray.count - windowSize
            let endIndex = flowArray.count
            smoothedFlowArray = Array(flowArray[startIndex..<endIndex])
        }
        
        smoothedFlowRate = smoothedFlowArray.reduce(0, { x, y in x + y }) / Double(smoothedFlowArray.count)
        
        oldtWeight = newWeight
    }
    
    
    //MARK: create linechart
    //set chart style
    func createLineChart(){
        view.addSubview(lineChart)
        
        lineChart.translatesAutoresizingMaskIntoConstraints = false
        lineChart.centerInSuperview()
        NSLayoutConstraint.activate([
            lineChart.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            lineChart.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10),
            lineChart.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 10),
            lineChart.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -10)
        ])
        
        
        let yAxis = lineChart.leftAxis
        lineChart.rightAxis.enabled = false
        yAxis.labelPosition = .insideChart
        view.bringSubviewToFront(StartStop)
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
        wDataSet.lineWidth = 2.5
        wDataSet.fill = ColorFill(color: .systemMint)
        //        wDataSet.fillAlpha = 0.2
        
        // could all of this be cleaner?
        fDataSet.colors = [UIColor.blue]
        fDataSet.circleColors = [UIColor.red]
        fDataSet.drawCirclesEnabled = false
        fDataSet.mode = .cubicBezier
        //        fDataSet.setColor(.systemMint)
        fDataSet.lineWidth = 2.5
        fDataSet.fill = ColorFill(color: .systemMint)
        fDataSet.fillAlpha = 0.2
        fDataSet.drawFilledEnabled = true
        
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
    
    func chartValueSelected(_ chartView: ChartViewBase, entry: ChartDataEntry, highlight: Highlight) {
        print(entry)
    }
    
    
    // Start and pause timer
    @IBAction func onBtnStop(_ sender: UIButton) {
        switch AcaiaManager.shared().connectedScale {
        case nil:
            performSegue(withIdentifier: "toConnectST", sender: self)
        case .some(_):
            switch timer {
            case nil:
                createTimer()
                isRunning = true
                print("Timer Started")
                StartStop.setTitle("Stop", for: UIControl.State.normal)
            case .some(_):
//                createCSV()
                timer?.invalidate()
                timer = nil
                StartStop.setTitle("Start", for: UIControl.State.normal)
                isRunning = false
                print("Timer Stopped")
                performSegue(withIdentifier: "toPostShot", sender: self)
            }
        }
    }

    
    
    //MARK: Save CSV to device
    func createCSV(){
        do {
            
            // Timestamp
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyyMMdd-HHmm"
            let timestamp = formatter.string(from: Date())
            
            // pre shot
            let preShotFileName = "\(timestamp)-preRecipie"
            let preShotDocumentDirURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            let preShotFileURL = preShotDocumentDirURL.appendingPathComponent(preShotFileName).appendingPathExtension("csv")
            
            let preShotStream = OutputStream(url: preShotFileURL, append: false)!
            let preShotcsv = try! CSVWriter(stream: preShotStream)
            
            try! preShotcsv.write(row: ["dose"   , String(dose)])
            try! preShotcsv.write(row: ["grindSize"   , String(grindSize)])
            try! preShotcsv.write(row: ["rpm"   , String(rpm)])
            try! preShotcsv.write(row: ["preWet"   , String(preWet)])
            
            preShotcsv.stream.close()
            
            // Weight Data
            let weightFileName = "\(timestamp)-WeightData"
            let weightDocumentDirURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            let weightFileURL = weightDocumentDirURL.appendingPathComponent(weightFileName).appendingPathExtension("csv")
            
            let weightStream = OutputStream(url: weightFileURL, append: false)!
            let weightCSVWriter = try CSVWriter(stream: weightStream)
            for data in ChartData.shared.weightData {
                try weightCSVWriter.write(row: ["\(data.x)", "\(data.y)"])
            }
            weightCSVWriter.stream.close()
            
            // Smoothed Flow Data
            let flowFileName = "\(timestamp)-SmoothedFlowData"
            let flowDocumentDirURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            let flowFileURL = flowDocumentDirURL.appendingPathComponent(flowFileName).appendingPathExtension("csv")
            
            let flowStream = OutputStream(url: flowFileURL, append: false)!
            let flowCSVWriter = try CSVWriter(stream: flowStream)
            for data in ChartData.shared.smoothedFlowData {
                try flowCSVWriter.write(row: ["\(data.x)", "\(data.y)"])
            }
            flowCSVWriter.stream.close()
            
            
            // pre shot
            let postShotFileName = "\(timestamp)-preRecipie"
            let postShotDocumentDirURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            let postShotFileURL = postShotDocumentDirURL.appendingPathComponent(postShotFileName).appendingPathExtension("csv")
            
            let postShotStream = OutputStream(url:  postShotFileURL, append: false)!
            let postShotcsv = try! CSVWriter(stream: postShotStream)
            
            try! postShotcsv.write(row: ["Body"         , body])
            try! postShotcsv.write(row: ["Acidity"      , Acidity])
            try! postShotcsv.write(row: ["Sweetness"    , Sweetness])
            try! postShotcsv.write(row: ["Bitterness"   , Bitterness])
            try! postShotcsv.write(row: ["Rating"       , Rating])
            
            postShotcsv.stream.close()
            
            // Upload CSVs
            uploadCSV(timestamp: timestamp,weightCSV: weightFileURL, flowCSV: flowFileURL, preShotCSV: preShotFileURL, postShotCSV: postShotFileURL)
        } catch {
            print("Error creating CSV files: \(error)")
        }
    }
    
   public func Finish(){
       createCSV()
       AcaiaManager.shared().connectedScale?.disconnect()
       ChartData.shared.smoothedFlowData.removeAll()
       ChartData.shared.weightData.removeAll()
       if timer != nil {
           timer?.invalidate()
           timer = nil
       }
   }
    
    
}






