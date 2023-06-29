import UIKit

class PostShotVC: UIViewController {

    @IBOutlet weak var bodySlider: UISlider!
    @IBOutlet weak var acidutySlider: UISlider!
    @IBOutlet weak var sweetnessSlider: UISlider!
    @IBOutlet weak var bitternessSlider: UISlider!
    @IBOutlet weak var ratingSlider: UISlider!
    
    @IBOutlet weak var bodyLabel: UILabel!
    @IBOutlet weak var acidutyLabel: UILabel!
    @IBOutlet weak var sweetnessLabel: UILabel!
    @IBOutlet weak var bitternessLabel: UILabel!
    @IBOutlet weak var ratingLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Set up the sliders
        setupSlider(bodySlider, forValue: Recipy.post.body)
        setupSlider(acidutySlider, forValue: Recipy.post.aciduty)
        setupSlider(sweetnessSlider, forValue: Recipy.post.sweetness)
        setupSlider(bitternessSlider, forValue: Recipy.post.bitterness)
        setupSlider(ratingSlider, forValue: Recipy.post.rating)
        
        // Set up the labels
        updateLabel(bodyLabel, withValue: bodySlider.value)
        updateLabel(acidutyLabel, withValue: acidutySlider.value)
        updateLabel(sweetnessLabel, withValue: sweetnessSlider.value)
        updateLabel(bitternessLabel, withValue: bitternessSlider.value)
        updateLabel(ratingLabel, withValue: ratingSlider.value)
    }

   
    @IBAction func sliderChanged(_ sender: Any) {
        guard let slider = sender as? UISlider else { return }
        let value = Double(slider.value)
        let label: UILabel
        
        switch slider {
        case bodySlider:
            Recipy.post.body = value
            label = bodyLabel
        case acidutySlider:
            Recipy.post.aciduty = value
            label = acidutyLabel
        case sweetnessSlider:
            Recipy.post.sweetness = value
            label = sweetnessLabel
        case bitternessSlider:
            Recipy.post.bitterness = value
            label = bitternessLabel
        case ratingSlider:
            Recipy.post.rating = value
            label = ratingLabel
        default:
            return
        }
        
        updateLabel(label, withValue: slider.value)
    }
    
    private func setupSlider(_ slider: UISlider, forValue value: Double?) {
        slider.minimumValue = 1
        slider.maximumValue = 10
        slider.value = Float(value ?? 5) // Default to 5 if value is nil
        slider.isContinuous = true
        slider.addTarget(self, action: #selector(sliderChanged(_:)), for: .valueChanged)
        
    }
    
    @IBAction func onButtonFinish(_ sender: UIButton) {
        performSegue(withIdentifier: "Finish", sender: self)
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "Finish" {
            let chartVC = segue.destination as! ChartVC
            chartVC.Finish()
        }
    }
    
    private func updateLabel(_ label: UILabel, withValue value: Float) {
        label.text = String(format: "%.1f", value)
    }
}


