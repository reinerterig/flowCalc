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
            updateLabel(bodyLabel, withValue: bodySlider.value, name: "Body")
            updateLabel(acidutyLabel, withValue: acidutySlider.value, name: "Acidity")
            updateLabel(sweetnessLabel, withValue: sweetnessSlider.value, name: "Sweetness")
            updateLabel(bitternessLabel, withValue: bitternessSlider.value, name: "Bitterness")
            updateLabel(ratingLabel, withValue: ratingSlider.value, name: "Rating")
    }

   
    @IBAction func sliderChanged(_ sender: Any) {
        guard let slider = sender as? UISlider else { return }
            let value = Double(slider.value)
            let label: UILabel
            let parameterName: String
            
            switch slider {
            case bodySlider:
                Recipy.post.body = value
                label = bodyLabel
                parameterName = "Body"
            case acidutySlider:
                Recipy.post.aciduty = value
                label = acidutyLabel
                parameterName = "Acidity"
            case sweetnessSlider:
                Recipy.post.sweetness = value
                label = sweetnessLabel
                parameterName = "Sweetness"
            case bitternessSlider:
                Recipy.post.bitterness = value
                label = bitternessLabel
                parameterName = "Bitterness"
            case ratingSlider:
                Recipy.post.rating = value
                label = ratingLabel
                parameterName = "Rating"
            default:
                return
            }
            
            updateLabel(label, withValue: slider.value, name: parameterName)
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
    
    private func updateLabel(_ label: UILabel, withValue value: Float, name: String) {
        label.text = "\(name): \(String(format: "%.1f", value))"
    }

}


