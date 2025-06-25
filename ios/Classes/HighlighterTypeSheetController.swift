import UIKit

final class HighlighterTypeSheetController: UIViewController {
    enum Action {
        case close
        case character
        case dialogue
    }
    
    private let completion: (Action) -> Void
    
    init(completion: @escaping (Action) -> Void) {
        self.completion = completion
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .custom
        transitioningDelegate = self
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.2)
        
        // Sheet container
        let sheet = UIView()
        sheet.backgroundColor = PDFViewController.color(from: "#FFF8EC")
        sheet.layer.cornerRadius = 40
        sheet.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        sheet.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(sheet)
        
        NSLayoutConstraint.activate([
            sheet.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            sheet.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            sheet.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // Close button
        let closeButton = UIButton(type: .custom)
        closeButton.setTitle("✕", for: .normal)
        closeButton.setTitleColor(.black, for: .normal)
        closeButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.backgroundColor = sheet.backgroundColor
        closeButton.layer.borderColor = UIColor.black.cgColor
        closeButton.layer.borderWidth = 2
        closeButton.layer.cornerRadius = 18
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        sheet.addSubview(closeButton)
        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: sheet.topAnchor, constant: -16),
            closeButton.centerXAnchor.constraint(equalTo: sheet.centerXAnchor),
            closeButton.widthAnchor.constraint(equalToConstant: 36),
            closeButton.heightAnchor.constraint(equalToConstant: 36)
        ])
        
        // Title
        let titleLabel = UILabel()
        titleLabel.text = "Highlighter Type"
        titleLabel.textAlignment = .center
        titleLabel.font = UIFont(name: "SheillaMonicaRegular", size: 24) ?? UIFont.systemFont(ofSize: 24, weight: .regular)
        titleLabel.textColor = .black
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        sheet.addSubview(titleLabel)
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: closeButton.bottomAnchor, constant: 25),
            titleLabel.centerXAnchor.constraint(equalTo: sheet.centerXAnchor)
        ])
        
        // Stack for buttons
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        sheet.addSubview(stack)
        
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 48),
            stack.leadingAnchor.constraint(equalTo: sheet.leadingAnchor, constant: 60),
            stack.trailingAnchor.constraint(equalTo: sheet.trailingAnchor, constant: -60),
            stack.bottomAnchor.constraint(equalTo: sheet.bottomAnchor, constant: -60)
        ])
        
        // Buttons
        let charButton = makeActionButton(title: "Highlight Character")
        charButton.addTarget(self, action: #selector(characterTapped), for: .touchUpInside)
        let dialogueButton = makeActionButton(title: "Highlight Dialogue")
        dialogueButton.addTarget(self, action: #selector(dialogueTapped), for: .touchUpInside)
        stack.addArrangedSubview(charButton)
        stack.addArrangedSubview(dialogueButton)
    }
    
    private func makeActionButton(title: String) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.monospacedSystemFont(ofSize: 17, weight: .regular)
        button.backgroundColor = .black
        button.layer.cornerRadius = 25
        button.translatesAutoresizingMaskIntoConstraints = false
        button.heightAnchor.constraint(equalToConstant: 51).isActive = true
        return button
    }
    
    @objc private func closeTapped() {
        self.completion(.close)
    }
    @objc private func characterTapped() {
        self.completion(.character)
    }
    @objc private func dialogueTapped() {
        self.completion(.dialogue)
    }
}

// MARK: UIViewControllerTransitioningDelegate
extension HighlighterTypeSheetController: UIViewControllerTransitioningDelegate {
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        SheetPresentAnimator(isPresenting: true)
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        SheetPresentAnimator(isPresenting: false)
    }
}

class SheetPresentAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    let isPresenting: Bool
    
    init(isPresenting: Bool) {
        self.isPresenting = isPresenting
        super.init()
    }
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        0.35
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        
        let container = transitionContext.containerView
        
        if isPresenting,
           let toView = transitionContext.view(forKey: .to)
        {
            container.addSubview(toView)
            toView.frame = container.bounds
            if let sheet = toView.subviews.first {
                let finalFrame = sheet.frame
                sheet.frame.origin.y = container.frame.height
                UIView.animate(withDuration: transitionDuration(using: transitionContext), delay: 0, options: [.curveEaseOut], animations: {
                    sheet.frame = finalFrame
                }) { finished in
                    transitionContext.completeTransition(finished)
                }
            } else {
                transitionContext.completeTransition(true)
            }
        }
        else if isPresenting == false,
                let fromView = transitionContext.view(forKey: .from)
        {
            if let sheet = fromView.subviews.first {
                UIView.animate(withDuration: transitionDuration(using: transitionContext), delay: 0, options: [.curveEaseIn], animations: {
                    sheet.frame.origin.y = container.frame.height
                }) { finished in
                    transitionContext.completeTransition(finished)
                }
            } else {
                transitionContext.completeTransition(true)
            }
        }
        else {
            transitionContext.completeTransition(false)
            return
        }
    }
}
