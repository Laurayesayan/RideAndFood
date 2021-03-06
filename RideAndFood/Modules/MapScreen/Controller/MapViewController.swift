//
//  MapViewController.swift
//  RideAndFood
//
//  Created by Nikita Gundorin on 25.10.2020.
//  Copyright © 2020 skillbox. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class MapViewController: UIViewController {
    
    // MARK: - UI
    
    private lazy var mapView: MKMapView = {
        let view = MKMapView()
        view.showsUserLocation = true
        view.showsCompass = false
        view.delegate = mapViewDelegate
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var locationImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "Location"))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private lazy var locationIVCenterYConstraint = locationImageView.centerYAnchor.constraint(equalTo: mapView.centerYAnchor)
    
    private lazy var statusBarBlurView: UIVisualEffectView = {
        let view = UIVisualEffectView(effect: UIBlurEffect(style: .light))
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    lazy var cardView: MapCardView = {
        let view = MapCardView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.taxiAction = taxiButtonPressed
        view.foodAction = foodButtonPressed
        return view
    }()
    
    private lazy var sideMenuView: SideMenuView = {
        let view = SideMenuView()
        view.viewController = self
        view.hideSideMenuCallback = { [weak self] in
            self?.toggleSideMenu(hide: true)
        }
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var backgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        view.alpha = 0
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var myLocationButton: UIButton = {
        let button = RoundButton(type: .system)
        button.bgImage = UIImage(named: "MyLocation")
        button.addTarget(self, action: #selector(myLocationButtonPressed), for: .touchUpInside)
        return button
    }()
    
    private lazy var menuButton: UIButton = {
        let button = RoundButton(type: .system)
        button.accessibilityIdentifier = "menuButton"
        button.bgImage = UIImage(named: "MenuButton")
        button.addTarget(self, action: #selector(menuButtonPressed), for: .touchUpInside)
        return button
    }()
    
    private lazy var backButton: UIButton = {
        let button = RoundButton(type: .system)
        button.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        button.addTarget(self, action: #selector(backButtonPressed), for: .touchUpInside)
        button.tintColor = Colors.getColor(.textBlack)()
        return button
    }()
    
    private lazy var personButton: UIButton = {
        let button = RoundButton(type: .system)
        button.bgImage = UIImage(named: "Person")
        button.addTarget(self, action: #selector(personButtonPressed), for: .touchUpInside)
        return button
    }()
    
    private lazy var cartButton: UIButton = {
        let button = RoundButton(type: .system)
        button.bgImage = UIImage(named: "CartButton")
        button.addTarget(self, action: #selector(showCart), for: .touchUpInside)
        button.alpha = 0
        return button
    }()
    
    private lazy var transparentView: UIView = {
        let view = UIView()
        view.backgroundColor = Colors.getColor(.tapIndicatorGray)()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard)))
        return view
    }()
    
    private lazy var addressInputView: OrderViewDirector = {
        let view = OrderViewDirector(type: .addressInput)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.currentAddress = currentPlacemark?.name
        view.delegate = self
        addressDelegate = view
        
        return view
    }()
    
    private lazy var notificationView: NotificationView = {
        let view = NotificationView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var cartView: CartView = {
        let view = CartView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var additionalCardView: CardView = {
        let view = CardView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var selectTariffView: SelectTariffView = {
        let view = SelectTariffView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var taxiConfirmationView = TaxiConfirmationView()
    
    private lazy var dimmerView: DimmerView = {
        let view = DimmerView()
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(hideCart)))
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var taxiTripInfoView = TaxiTripInfoView()
    private lazy var taxiTripFinishedView = TaxiTripFinishedView()
    
    // MARK: - Public properties
    
    var state: MapScreenState = .main {
        didSet {
            stateChanged()
        }
    }
    
    // MARK: - Private properties
    
    private let accessManager = AccessLocationManager()
    private let regionInMeters: Double = 100
    private lazy var mapViewDelegate: MapViewDelegate = {
        let delegate = MapViewDelegate()
        delegate.mapViewCenterUpdatedCallback = { [weak self] placemark in
            self?.currentPlacemark = placemark
            self?.updateAnnotations()
        }
        delegate.mapViewController = self
        return delegate
    }()
    
    private var currentPlacemark: CLPlacemark? {
        didSet {
            cardView.address = currentPlacemark?.name
            addressDelegate?.currentAddressChanged(newAddress: currentPlacemark?.name)
        }
    }
    
    private let taxiOrderModelHandler = OrderTaxiModelHandler.shared
    
    private lazy var taxiActiveOrderView: TaxiActiveOrderView = {
        let view = TaxiActiveOrderView()
        view.frame = CGRect(x: cardView.frame.origin.x, y: cardView.frame.origin.y, width: cardView.frame.width, height: cardView.frame.height + activeOrderViewPadding)
        
        var swipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(dismissActiveOrderViews))
        swipeGesture.direction = .down
        view.addGestureRecognizer(swipeGesture)
        
        swipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(showActiveOrderView))
        swipeGesture.direction = .up
        view.addGestureRecognizer(swipeGesture)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(showExpandedTaxiActiveOrderView))
        view.addGestureRecognizer(tapGesture)
        
        cardView.isTaxiButtonEnable = false
        
        return view
    }()
    
    private lazy var foodActiveOrderView: FoodActiveOrderView = {
        let view = FoodActiveOrderView()
        if isTaxiActiveOrder {
            view.frame = CGRect(x: cardView.frame.origin.x, y: cardView.frame.origin.y, width: cardView.frame.width, height: cardView.frame.height + 2 * activeOrderViewPadding)
        } else {
            view.frame = CGRect(x: cardView.frame.origin.x, y: cardView.frame.origin.y, width: cardView.frame.width, height: cardView.frame.height + activeOrderViewPadding)
        }
        
        var swipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(dismissActiveOrderViews))
        swipeGesture.direction = .down
        view.addGestureRecognizer(swipeGesture)
        
        swipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(showActiveOrderView))
        swipeGesture.direction = .up
        view.addGestureRecognizer(swipeGesture)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(showExpandedFoodActiveOrderView))
        view.addGestureRecognizer(tapGesture)
        
        return view
    }()
    
    private lazy var activeOrderCounterView: UIButton = {
        let view = UIButton(type: .system)
        view.setBackgroundImage(UIImage(named: CustomImagesNames.gradient.rawValue), for: .normal)
        view.isUserInteractionEnabled = false
        view.setTitleColor(Colors.getColor(.buttonWhite)(), for: .normal)
        view.isHidden = true
        view.translatesAutoresizingMaskIntoConstraints = false
        
        return view
    }()
    
    private var isActiveOrder: Bool? {
        didSet {
            if let cardViewIndex = view.subviews.firstIndex(of: cardView) {
                if isFoodActiveOrder || isTaxiActiveOrder {
                    myLocationButton.isHidden = true
                    locationImageView.isHidden = true
                    
                    if isFoodActiveOrder && isTaxiActiveOrder {
                        view.insertSubview(taxiActiveOrderView, at: cardViewIndex - 1)
                        view.insertSubview(foodActiveOrderView, at: cardViewIndex - 2)
                        foodActiveOrderView.isLastView = true
                        taxiActiveOrderView.isLastView = false
                        activeOrderCounterView.setTitle(getActiveOrderCounterString(orderCount: 2), for: .normal)
                        taxiActiveOrderView.show()
                        foodActiveOrderView.show()
                        cardView.isTaxiButtonEnable = false
                        cardView.isFoodButtonEnable = false
                    } else if isTaxiActiveOrder {
                        taxiActiveOrderView.isLastView = true
                        view.insertSubview(taxiActiveOrderView, at: cardViewIndex - 1)
                        activeOrderCounterView.setTitle(getActiveOrderCounterString(orderCount: 1), for: .normal)
                        taxiActiveOrderView.show()
                        cardView.isFoodButtonEnable = true
                        cardView.isTaxiButtonEnable = false
                    } else if isFoodActiveOrder {
                        foodActiveOrderView.isLastView = true
                        view.insertSubview(foodActiveOrderView, at: cardViewIndex - 1)
                        activeOrderCounterView.setTitle(getActiveOrderCounterString(orderCount: 1), for: .normal)
                        foodActiveOrderView.show()
                        cardView.isTaxiButtonEnable = true
                        cardView.isFoodButtonEnable = false
                    }
                    
                    activeOrderCounterView.isHidden = false
                    
                    let swipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(showActiveOrderView))
                    swipeGesture.direction = .up
                    cardView.addGestureRecognizer(swipeGesture)
                } else {
                    menuButton.isHidden = false
                    personButton.isHidden = false
                    myLocationButton.isHidden = false
                    locationImageView.isHidden = false
                    activeOrderCounterView.isHidden = true
                    cardView.gestureRecognizers?.removeAll()
                    cardView.isTaxiButtonEnable = true
                    cardView.isFoodButtonEnable = true
                }
            }
        }
    }
    
    private var isFoodActiveOrder = false
    private var isTaxiActiveOrder = false
    
    private weak var addressDelegate: MapViewCurrentAddressDelegate?
    
    private lazy var sideMenuLeftConstraint = sideMenuView.leftAnchor.constraint(equalTo: view.leftAnchor,
                                                                                 constant: sideMenuOffset)
    private lazy var sideMenuShownConstraint = sideMenuView.rightAnchor.constraint(equalTo: view.rightAnchor,
                                                                                   constant: -sideMenuPadding)
    private lazy var sideMenuHiddenConstraint = sideMenuView.rightAnchor.constraint(equalTo: view.leftAnchor,
                                                                                    constant: sideMenuOffset)
    
    private lazy var backgroundLeftConstraint = backgroundView.leftAnchor.constraint(equalTo: view.leftAnchor,
                                                                                     constant: sideMenuOffset)
    private lazy var backgroundShownConstraint = backgroundView.rightAnchor.constraint(equalTo: view.rightAnchor)
    private lazy var backgroundHiddenConstraint = backgroundView.rightAnchor.constraint(equalTo: view.leftAnchor,
                                                                                        constant: sideMenuOffset)
    private lazy var additionalCardViewBottomConstraint = additionalCardView.bottomAnchor.constraint(equalTo: view.bottomAnchor,
                                                                                                     constant: additionalCardViewOffset)
    private let padding: CGFloat = 25
    private let sideMenuPadding: CGFloat = 42
    private let activeOrderViewPadding: CGFloat = 10
    private lazy var sideMenuOffset: CGFloat = -500
    private lazy var additionalCardViewOffset: CGFloat = 1000
    
    private var fromAnnotation: FromAnnotation? {
        mapView.annotations.first(where: { $0 is FromAnnotation }) as? FromAnnotation
    }
    
    private var toAnnotation: ToAnnotation? {
        mapView.annotations.first(where: { $0 is ToAnnotation }) as? ToAnnotation
    }
    
    private var carAnnotations: [CarAnnotation] {
        mapView.annotations.compactMap { $0 as? CarAnnotation }
    }
    
    private var routeOverlay = MKPolyline()
    
    // MARK: - Lifecycle methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupLayout()
        
        TariffViewController.delegate = self
        PromotionDetailsViewController.delegate = self
        AddAddresViewController.delegate = self
        CartModel.shared.observers.append(self)
        NotificationCenter.default.addObserver(self, selector: #selector(managedObjectContextObjectsDidChange), name: NSNotification.Name.NSManagedObjectContextObjectsDidChange, object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if UserConfig.shared.settings.language != sideMenuView.currentLanguage {
            sideMenuView.updateTexts()
            cardView.updateTexts()
        }
        
        if (UserConfig.shared.userId > 0) {
            accessManager.requestLocationAccess { [weak self] (coordinate, error) in
                guard let coordinate = coordinate, error == nil else {
                    print(error ?? "location is not available")
                    return
                }
                self?.centerViewOn(coordinate: coordinate)
            }
            
            ServerApi.shared.getSettings { settings, _ in
                if let settings = settings {
                    UserConfig.shared.settings = settings
                }
            }
            checkIfTaxiActiveOrderExists()
            checkIfFoodActiveOrderExists()
            checkCartHasGoods()
        } else {
            let vc = LoginViewController()
            vc.modalPresentationStyle = .fullScreen
            present(vc, animated: true)
        }
        taxiOrderModelHandler.finishOrder()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        locationIVCenterYConstraint.constant = -(locationImageView.image?.size.height ?? 0) / 2
        cardView.bottomPadding = view.safeAreaInsets.bottom
    }
    
    // MARK: - Private methods
    
    private func setupLayout() {
        view.addSubview(mapView)
        view.addSubview(locationImageView)
        view.addSubview(statusBarBlurView)
        view.addSubview(cardView)
        view.addSubview(myLocationButton)
        view.addSubview(menuButton)
        view.addSubview(personButton)
        view.addSubview(cartButton)
        view.addSubview(activeOrderCounterView)
        view.addSubview(backgroundView)
        view.addSubview(sideMenuView)
        
        NSLayoutConstraint.activate([
            mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mapView.topAnchor.constraint(equalTo: view.topAnchor),
            mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            locationImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            locationIVCenterYConstraint,
            statusBarBlurView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            statusBarBlurView.topAnchor.constraint(equalTo: view.topAnchor),
            statusBarBlurView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            statusBarBlurView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            cardView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            cardView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            cardView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            myLocationButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -padding),
            myLocationButton.bottomAnchor.constraint(equalTo: cardView.topAnchor, constant: -padding*5),
            menuButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: padding),
            menuButton.topAnchor.constraint(equalTo: statusBarBlurView.bottomAnchor, constant: padding),
            sideMenuView.topAnchor.constraint(equalTo: view.topAnchor),
            sideMenuView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            sideMenuHiddenConstraint,
            sideMenuLeftConstraint,
            backgroundView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            backgroundHiddenConstraint,
            backgroundLeftConstraint,
            personButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: padding),
            personButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -padding),
            cartButton.topAnchor.constraint(equalTo: personButton.bottomAnchor, constant: padding),
            cartButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -padding),
            activeOrderCounterView.heightAnchor.constraint(equalToConstant: 40),
            activeOrderCounterView.widthAnchor.constraint(equalToConstant: 165),
            activeOrderCounterView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activeOrderCounterView.centerYAnchor.constraint(equalTo: menuButton.centerYAnchor)
        ])
    }
    
    private func centerViewOn(coordinate: CLLocationCoordinate2D) {
        let region = MKCoordinateRegion.init(center: coordinate,
                                             latitudinalMeters: regionInMeters,
                                             longitudinalMeters: regionInMeters)
        mapView.setRegion(region, animated: true)
    }
    
    private func lookUpCurrentLocation(location: CLLocation, completionHandler: @escaping (CLPlacemark?) -> Void ) {
        
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { (placemarks, error) in
            if error == nil {
                let firstLocation = placemarks?[0]
                completionHandler(firstLocation)
            }
            else {
                completionHandler(nil)
            }
        }
    }
    
    private func toggleSideMenu(hide: Bool) {
        var animationOptions: UIView.AnimationOptions
        if (hide) {
            sideMenuLeftConstraint.constant = self.sideMenuOffset
            sideMenuShownConstraint.isActive = false
            sideMenuHiddenConstraint.isActive = true
            animationOptions = .curveEaseIn
        } else {
            sideMenuHiddenConstraint.isActive = false
            sideMenuShownConstraint.isActive = true
            sideMenuLeftConstraint.constant = 0
            animationOptions = .curveEaseOut
        }
        
        UIView.animate(withDuration: 0.3, delay: 0, options: animationOptions) { [weak self] in
            self?.view.layoutIfNeeded()
        }
        
        if (!hide) {
            self.backgroundHiddenConstraint.isActive = false
            self.backgroundShownConstraint.isActive = true
            self.backgroundLeftConstraint.constant = 0
        }
        
        UIView.animate(withDuration: 0.3, delay: 0, options: animationOptions, animations: { [weak self] in
            self?.backgroundView.alpha = hide ? 0 : 0.3
        }, completion: { [weak self] _ in
            guard let self = self else { return }
            if (hide) {
                self.backgroundLeftConstraint.constant = self.sideMenuOffset
                self.backgroundShownConstraint.isActive = false
                self.backgroundHiddenConstraint.isActive = true
            }
        })
    }
    
    private func initializeTaxiOrderView() {
        self.view.addSubview(addressInputView)
        cardView.isHidden = true
        
        (NSLayoutConstraint.activate([addressInputView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                                      addressInputView.trailingAnchor.constraint(equalTo: view.trailingAnchor), addressInputView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: view.safeAreaInsets.bottom), addressInputView.topAnchor.constraint(greaterThanOrEqualTo: view.safeAreaLayoutGuide.topAnchor, constant: padding)]))
        addressInputView.show()
    }
    
    private func initializeSelectTariffView(_ firstTextFieldText: String?, _ secondTextFieldText: String?) {
        backButton.removeFromSuperview()
        personButton.isHidden = true
        selectTariffView.delegate = self
        selectTariffView.firstTextField.textField.text = firstTextFieldText
        selectTariffView.secondTextField.textField.text = secondTextFieldText
        
        view.addSubview(selectTariffView)
        
        NSLayoutConstraint.activate([selectTariffView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                                     selectTariffView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                                     selectTariffView.topAnchor.constraint(equalTo: view.topAnchor),
                                     selectTariffView.bottomAnchor.constraint(equalTo: view.bottomAnchor)])
        view.layoutIfNeeded()
        selectTariffView.show()
    }
    
    @objc private func dismissKeyboard() {
        if self.view.endEditing(false) {
            self.view.endEditing(true)
        }
    }
    
    private func initializeBackButton() {
        menuButton.isHidden = true
        view.addSubview(backButton)
        
        backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: padding).isActive = true
        backButton.topAnchor.constraint(equalTo: statusBarBlurView.bottomAnchor, constant: padding).isActive = true
    }
    
    private func checkCartHasGoods() {
        guard CartModel.getCart().rows.count > 0 else {
            notificationView.removeFromSuperview()
            cartButton.alpha = 0
            return
        }
        guard notificationView.superview == nil else { return }
        notificationView.configure(with: .init(messageText: FoodStrings.haveGoodsInCart.text(),
                                               iconImage: UIImage(named: "CartLight"),
                                               closeBlock: { [weak self] in
                                                UIView.animate(withDuration: 0.3, animations: {
                                                    self?.notificationView.alpha = 0
                                                }) { [weak self] _ in
                                                    self?.notificationView.removeFromSuperview()
                                                }
                                               },
                                               tappedBlock: { [weak self] in
                                                self?.showCart()
                                               }))
        view.insertSubview(notificationView, belowSubview: cardView)
        NSLayoutConstraint.activate([
            notificationView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: padding),
            notificationView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -padding),
            notificationView.bottomAnchor.constraint(equalTo: cardView.topAnchor, constant: -2 * padding)
        ])
        UIView.animate(withDuration: 0.3) {
            self.notificationView.alpha = 1
            self.cartButton.alpha = 1
        }
    }
    
    private func checkIfTaxiActiveOrderExists() {
        DispatchQueue.main.asyncAfter(deadline: .now() + generalDelay) { [weak self] in
            guard let self = self else { return }
            if OrderTaxiModelHandler.shared.getTaxiOrder() != nil {
                self.isTaxiActiveOrder = true
                self.isActiveOrder = true
            }
        }
    }
    
    private func checkIfFoodActiveOrderExists() {
        DispatchQueue.main.asyncAfter(deadline: .now() + generalDelay) { [weak self] in
            guard let self = self else { return }
            if OrderFoodModelHandler.shared.getFoodOrder() != nil, OrderFoodModelHandler.shared.getFoodOrder()?.time != 0 {
                self.isFoodActiveOrder = true
                self.isActiveOrder = true
            }
        }
    }
    
    @objc private func showCart() {
        cartView.removeFromSuperview()
        let cart = CartModel.getCart()
        cartView = CartView()
        cartView.cartViewDelegate = self
        
        cartView.configure(with: .init(cartRows: cart.rows,
                                       sum: cart.sum,
                                       deliveryTimeInMinutes: Int.random(in: 5...120),
                                       deliveryCost: 0,
                                       shopName: cart.shopName,
                                       backButtonTappedBlock: { [weak self] in
                                        self?.hideCart()
                                       }))
        additionalCardView.configure(with: .init(contentView: cartView,
                                                 style: .light,
                                                 paddingTop: 0,
                                                 paddingBottom: padding,
                                                 paddingX: 0,
                                                 didSwipeDownCallback: { [weak self] in
                                                    self?.hideCart()
                                                 }))
        showAdditionalCardView()
    }
    
    private func showAdditionalCardView(showDimmer: Bool = true) {
        view.addSubview(dimmerView)
        view.addSubview(additionalCardView)
        
        NSLayoutConstraint.activate([
            dimmerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dimmerView.topAnchor.constraint(equalTo: view.topAnchor),
            dimmerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            dimmerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            additionalCardView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            additionalCardView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            additionalCardViewBottomConstraint
        ])
        view.layoutIfNeeded()
        additionalCardViewBottomConstraint.constant = 0
        if showDimmer {
            dimmerView.show()
        }
        
        UIView.animate(withDuration: 0.2) {
            self.view.layoutIfNeeded()
        }
    }
    
    private func hideAdditionalCardView(completion: (() -> Void)? = nil) {
        additionalCardViewBottomConstraint.constant = additionalCardViewOffset
        dimmerView.hide()
        UIView.animate(withDuration: 0.2) {
            self.view.layoutIfNeeded()
        } completion: { _ in
            self.dimmerView.removeFromSuperview()
            self.additionalCardView.removeFromSuperview()
            completion?()
        }
    }
    
    private func showTaxiConfirmationView() {
        guard let order = taxiOrderModelHandler.getTaxiOrder() else { return }
        
        taxiConfirmationView.configure(with: .init(taxiOrderModel: order) { [weak self] in
            self?.hideAdditionalCardView(completion: {
                self?.showTaxiArrivingView()
            })
        } secondaryButtonPressedBlock: { [weak self] in
            self?.taxiOrderModelHandler.finishOrder()
            self?.hideAdditionalCardView()
            self?.cencelOrderButtonPressed()
        })
        additionalCardView.configure(with: .init(contentView: taxiConfirmationView,
                                                 style: .light,
                                                 paddingTop: 0,
                                                 paddingBottom: 0,
                                                 paddingX: 0,
                                                 didSwipeDownCallback: { [weak self] in
                                                    self?.taxiOrderModelHandler.finishOrder()
                                                    self?.hideAdditionalCardView()
                                                 }))
        showAdditionalCardView()
    }
    
    private func showTaxiArrivingView() {
        state = .waitForTaxi
        guard let order = taxiOrderModelHandler.getTaxiOrder() else { return }
        let taxiArrivingView = TaxiArrivingView()
        taxiArrivingView.configure(with: .init(carName: order.car, carColor: order.color))
        additionalCardView.configure(with: .init(contentView: taxiArrivingView,
                                                 paddingBottom: padding,
                                                 didSwipeDownCallback: { [weak self] in
                                                    self?.hideAdditionalCardView()
                                                    self?.state = .trip
                                                    self?.cardView.isHidden = false
                                                    // Mock trip finish
                                                    DispatchQueue.main.asyncAfter(deadline: .now() + .random(in: 15...16)) {
                                                        self?.taxiOrderModelHandler.finishOrder()
                                                        self?.hideAdditionalCardView {
                                                            self?.showTripFinishedView()
                                                        }
                                                    }
                                                 }))
        showAdditionalCardView(showDimmer: false)
        
        // Mock taxi arrived
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            if let coordinate = self?.fromAnnotation?.coordinate {
                self?.carAnnotations.first?.setCoordinate(coordinate: coordinate)
                self?.centerViewOn(coordinate: coordinate)
            }
            if let overlay = self?.routeOverlay {
                self?.mapView.removeOverlay(overlay)
            }
        }
    }
    
    private func showTaxiTripInfoView() {
        guard let order = taxiOrderModelHandler.getTaxiOrder() else { return }
        taxiTripInfoView.configure(with: .init(addressFrom: order.from,
                                               addressTo: order.to,
                                               driverName: order.driver,
                                               carName: "\(order.color) \(order.car)",
                                               tripTimeInMinutes: Int.random(in: 1...15),
                                               primaryButtonPressedBlock: { [weak self] in
                                                self?.hideAdditionalCardView()
                                                self?.foodButtonPressed()
                                               },
                                               secondaryButtonPressedBlock: { [weak self] in
                                                if let controller = UIStoryboard.init(name: "SupportService", bundle: nil)
                                                    .instantiateViewController(withIdentifier: "SupportID") as? UINavigationController {
                                                    controller.modalPresentationStyle = .fullScreen
                                                    self?.present(controller, animated: true)
                                                }
                                               }))
        additionalCardView.configure(with: .init(contentView: taxiTripInfoView,
                                                 paddingBottom: 0,
                                                 paddingX: 0,
                                                 didSwipeDownCallback: { [weak self] in
                                                    self?.hideAdditionalCardView()
                                                 }))
        showAdditionalCardView()
    }
    
    private func showTripFinishedView() {
        state = .main
        taxiTripFinishedView.configure(with: .init(payment: .init(id: 5,
                                                                  paid: 544,
                                                                  method: "card",
                                                                  status: "paid",
                                                                  order: 5,
                                                                  paymentCard: .init(number: "**** 6666",
                                                                                     system: "MasterCard"))) { [weak self] in
                                                                                        self?.hideAdditionalCardView()
                                                                                     })
        additionalCardView.configure(with: .init(contentView: taxiTripFinishedView,
                                                 didSwipeDownCallback: { [weak self] in
                                                    self?.hideAdditionalCardView()
                                                 }))
        showAdditionalCardView()
        taxiActiveOrderView.removeFromSuperview()
        isTaxiActiveOrder = false
        isActiveOrder = true
    }
    
    private func updateAnnotations() {
        switch state {
        case .selectFromAddress:
            fromAnnotation?.setCoordinate(coordinate: mapView.centerCoordinate)
        case .selectToAddress:
            toAnnotation?.setCoordinate(coordinate: mapView.centerCoordinate)
        default:
            return
        }
    }
    
    private func stateChanged() {
        switch state {
        case .main:
            locationImageView.isHidden = false
            myLocationButtonPressed()
            mapView.removeAnnotations(mapView.annotations.filter { $0 is CarAnnotation || $0 is FromAnnotation || $0 is ToAnnotation })
            mapView.removeOverlay(routeOverlay)
        case .selectFromAddress:
            locationImageView.isHidden = true
            if fromAnnotation == nil {
                mapView.addAnnotation(FromAnnotation(coordinate: mapView.centerCoordinate))
            }
        case .selectToAddress:
            locationImageView.isHidden = true
            if toAnnotation == nil {
                mapView.addAnnotation(ToAnnotation(coordinate: mapView.centerCoordinate))
            }
        case .orderTaxi:
            locationImageView.isHidden = true
            var fromAnnotation: FromAnnotation
            var toAnnotation: ToAnnotation
            
            if let fromAnn = self.fromAnnotation {
                fromAnnotation = fromAnn
            } else {
                fromAnnotation = FromAnnotation(coordinate: mapView.userLocation.coordinate)
                mapView.addAnnotation(fromAnnotation)
            }
            if let toAnn = self.toAnnotation {
                toAnnotation = toAnn
            } else {
                toAnnotation = ToAnnotation(coordinate: fromAnnotation.coordinate.randomAround)
                mapView.addAnnotation(toAnnotation)
            }
            mapView.showAnnotations([fromAnnotation, toAnnotation], animated: true)
            showRouteOnMap(fromCoordinate: fromAnnotation.coordinate, toCoordinate: toAnnotation.coordinate)
        case .searchForTaxi:
            locationImageView.isHidden = true
            if carAnnotations.count < 2 {
                for _ in 0...5 {
                    mapView.addAnnotation(CarAnnotation(coordinate: (fromAnnotation?.coordinate
                                                                        ?? mapView.userLocation.coordinate).randomAround))
                }
            }
            var annotations: [MKAnnotation] = carAnnotations
            if let fromAnnotation = fromAnnotation {
                annotations.append(fromAnnotation)
            }
            mapView.showAnnotations(annotations, animated: true)
        case .waitForTaxi:
            locationImageView.isHidden = true
            var carAnnotation: CarAnnotation
            if let carAnn = carAnnotations.first {
                carAnnotation = carAnn
                mapView.removeAnnotations(carAnnotations)
            } else {
                carAnnotation = CarAnnotation(coordinate: (fromAnnotation?.coordinate
                                                            ?? mapView.userLocation.coordinate).randomAround)
            }
            mapView.addAnnotation(carAnnotation)
            var annotations: [MKAnnotation] = [carAnnotation]
            if let fromAnnotation = fromAnnotation {
                annotations.append(fromAnnotation)
                showRouteOnMap(fromCoordinate: carAnnotation.coordinate, toCoordinate: fromAnnotation.coordinate)
            }
        case .trip:
            locationImageView.isHidden = true
            var toAnnotation: ToAnnotation
            var carAnnotation: CarAnnotation
            if let toAnn = self.toAnnotation {
                toAnnotation = toAnn
            } else {
                toAnnotation = ToAnnotation(coordinate: (fromAnnotation?.coordinate
                                                            ?? mapView.userLocation.coordinate).randomAround)
                mapView.addAnnotation(toAnnotation)
            }
            
            if let carAnn = carAnnotations.first {
                carAnnotation = carAnn
            } else {
                carAnnotation = CarAnnotation(coordinate: (fromAnnotation?.coordinate
                                                            ?? mapView.userLocation.coordinate).randomAround)
                mapView.addAnnotation(carAnnotation)
            }
            showRouteOnMap(fromCoordinate: carAnnotation.coordinate, toCoordinate: toAnnotation.coordinate)
        }
    }
    
    private func showRouteOnMap(fromCoordinate: CLLocationCoordinate2D, toCoordinate: CLLocationCoordinate2D) {
        mapView.removeOverlay(routeOverlay)
        let sourcePlacemark = MKPlacemark(coordinate: fromCoordinate, addressDictionary: nil)
        let destinationPlacemark = MKPlacemark(coordinate: toCoordinate, addressDictionary: nil)
        
        let sourceMapItem = MKMapItem(placemark: sourcePlacemark)
        let destinationMapItem = MKMapItem(placemark: destinationPlacemark)
        
        let sourceAnnotation = MKPointAnnotation()
        
        if let location = sourcePlacemark.location {
            sourceAnnotation.coordinate = location.coordinate
        }
        
        let destinationAnnotation = MKPointAnnotation()
        
        if let location = destinationPlacemark.location {
            destinationAnnotation.coordinate = location.coordinate
        }
        
        self.mapView.showAnnotations([sourceAnnotation,destinationAnnotation], animated: true )
        
        let directionRequest = MKDirections.Request()
        directionRequest.source = sourceMapItem
        directionRequest.destination = destinationMapItem
        directionRequest.transportType = .automobile
        
        // Calculate the direction
        let directions = MKDirections(request: directionRequest)
        
        directions.calculate { (response, error) -> Void in
            guard let response = response else {
                return
            }
            
            let route = response.routes[0]
            self.mapView.addOverlay((route.polyline), level: MKOverlayLevel.aboveRoads)
            self.routeOverlay = route.polyline
            let rect = route.polyline.boundingMapRect
            let region = MKCoordinateRegion(.init(x: rect.minX - rect.width * 0.1,
                                                  y: rect.minY - rect.height * 0.1,
                                                  width: rect.width * 1.2,
                                                  height: rect.height * 3))
            self.mapView.setRegion(region, animated: true)
        }
    }
    
    @objc private func hideCart() {
        hideAdditionalCardView()
    }
    
    @objc private func myLocationButtonPressed() {
        guard let coordinate = accessManager.location?.coordinate else { return }
        centerViewOn(coordinate: coordinate)
    }
    
    @objc private func menuButtonPressed() {
        toggleSideMenu(hide: false)
    }
    
    @objc private func taxiButtonPressed() {
        initializeBackButton()
        initializeTaxiOrderView()
    }
    
    @objc private func foodButtonPressed() {
        let foodView = FoodView()
        foodView.currentUserAddress = cardView.address
        foodView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(foodView)
        
        NSLayoutConstraint.activate([
            foodView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            foodView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            foodView.topAnchor.constraint(equalTo: view.topAnchor),
            foodView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    @objc private func personButtonPressed() {
        let vc = UINavigationController(rootViewController: ProfileViewController())
        vc.modalPresentationStyle = .fullScreen
        present(vc, animated: true)
    }
    
    @objc private func backButtonPressed() {
        if let currentView = view.subviews.last as? OrderViewDirector {
            if let type = currentView.orderViewType, type == .addressInput {
                backButton.removeFromSuperview()
                menuButton.isHidden = false
                cardView.isHidden = false
            } else {
                if let indexOfCurrentView = view.subviews.firstIndex(of: currentView) {
                    view.subviews[indexOfCurrentView - 1].isHidden = false
                    addressDelegate = view.subviews[indexOfCurrentView - 1] as? MapViewCurrentAddressDelegate
                }
            }
            
            currentView.dismiss()
        }
    }
    
    @objc private func confirmAddressButtonPressed() {
        if let currentView = view.subviews.last as? OrderViewDirector {
            currentView.dismiss(withUpdateStatus: false)
            initializeSelectTariffView(currentView.firstTextView.textField.text, currentView.secondTextView.textField.text)
        }
        state = .orderTaxi
    }
    
    @objc private func showActiveOrderView() {
        if isTaxiActiveOrder && isFoodActiveOrder {
            foodActiveOrderView.showMore(originY: UIScreen.main.bounds.height - taxiActiveOrderView.frame.height - activeOrderViewPadding + padding)
            taxiActiveOrderView.showMore()
        } else if isTaxiActiveOrder {
            taxiActiveOrderView.showMore()
        } else if isFoodActiveOrder {
            foodActiveOrderView.showMore()
        }
    }
    
    @objc private func dismissActiveOrderViews() {
        if isTaxiActiveOrder && isFoodActiveOrder {
            foodActiveOrderView.dismiss()
            taxiActiveOrderView.dismiss()
            foodActiveOrderView.dismiss(padding: padding)
        } else if isTaxiActiveOrder {
            taxiActiveOrderView.dismiss()
        } else if isFoodActiveOrder {
            foodActiveOrderView.dismiss()
        }
    }
    
    @objc private func managedObjectContextObjectsDidChange(notification: NSNotification) {
        guard let userInfo = notification.userInfo else { return }
        
        if let inserts = userInfo[NSInsertedObjectsKey] as? Set<NSManagedObject>, inserts.count > 0 {
            checkIfTaxiActiveOrderExists()
            
            checkIfFoodActiveOrderExists()
        }
        
        if let updates = userInfo[NSUpdatedObjectsKey] as? Set<NSManagedObject>, updates.count > 0 {
            checkIfTaxiActiveOrderExists()
            
            checkIfFoodActiveOrderExists()
        }
        
        if let deletes = userInfo[NSDeletedObjectsKey] as? Set<NSManagedObject>, deletes.count > 0 {
            if OrderTaxiModelHandler.shared.getTaxiOrder() == nil {
                DispatchQueue.main.async { [weak self] in
                    self?.taxiActiveOrderView.removeFromSuperview()
                }
            }
            // Здесь нужно будет удалить вьюшки активных заказов и вернуть состояние стартового экрана.
        }
    }
    
    @objc private func showExpandedFoodActiveOrderView() {
        let expandedFoodActiveOrderView = ExpandedActiveOrderView(type: .foodActiveOrderView)
        expandedFoodActiveOrderView.delegate = self
        
        view.addSubview(expandedFoodActiveOrderView)
        
        dismissActiveOrderViews()
        expandedFoodActiveOrderView.show(after: generalDelay)
    }
    
    @objc private func showExpandedTaxiActiveOrderView() {
        dismissActiveOrderViews()
        showTaxiTripInfoView()
    }
}

// MARK: - Extensions
extension MapViewController: OrderViewDelegate {
    func stateChanged(to newState: MapScreenState) {
        if newState == .selectToAddress {
            if let toCoordinate = toAnnotation?.coordinate {
                centerViewOn(coordinate: toCoordinate)
            }
            locationImageView.image = UIImage(named: "LocationTo")
        } else if newState == .selectFromAddress {
            if let fromCoordinate = fromAnnotation?.coordinate {
                centerViewOn(coordinate: fromCoordinate)
            }
            locationImageView.image = UIImage(named: "Location")
        }
        state = newState
    }
    
    func mapButtonTapped(senderType: TextViewType) {
        if senderType == .destinationAddress {
            let destinationAddressFromMapView = OrderViewDirector(type: .destinationAddressFromMap)
            destinationAddressFromMapView.currentAddress = currentPlacemark?.name
            addNewOrderView(newSubview: destinationAddressFromMapView)
        }
    }
    
    func locationButtonTapped(senderType: TextViewType) {
        switch senderType {
        case .currentAddress:
            let currentAddressDetailView = OrderViewDirector(type: .currentAddressDetail)
            currentAddressDetailView.currentAddress = currentPlacemark?.name
            addNewOrderView(newSubview: currentAddressDetailView)
        case .destinationAddress:
            let destinationAddressDetailView = OrderViewDirector(type: .destinationAddressDetail)
            destinationAddressDetailView.currentAddress = currentPlacemark?.name
            addNewOrderView(newSubview: destinationAddressDetailView)
            
        default:
            break
        }
    }
    
    func buttonTapped(senderType: OrderViewType, addressInfo: String?) {
        switch senderType {
        case .addressInput:
            confirmAddressButtonPressed()
            backButtonPressed()
        case .currentAddressDetail:
            backButtonPressed()
        case .destinationAddressDetail:
            // add addressInfo to the post model
            backButtonPressed()
        case .orderPrice:
            break // describe behaviour of order price view's button
        case .confirmationCode:
            break // describe behaviour of confirmation code view's button
        case .destinationAddressFromMap:
            addressInputView.secondTextView.setText(addressInfo)
            backButtonPressed()
        }
    }
    
    private func addNewOrderView(newSubview: OrderViewDirector) {
        dismissKeyboard()
        
        if let currentView = view.subviews.last as? OrderViewDirector {
            currentView.isHidden = true
        }
        
        self.view.addSubview(newSubview)
        newSubview.translatesAutoresizingMaskIntoConstraints = false
        addressDelegate = newSubview
        newSubview.delegate = self
        
        (NSLayoutConstraint.activate([newSubview.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                                      newSubview.trailingAnchor.constraint(equalTo: view.trailingAnchor), newSubview.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: view.safeAreaInsets.bottom), newSubview.topAnchor.constraint(greaterThanOrEqualTo: view.safeAreaLayoutGuide.topAnchor, constant: padding)]))
        
        newSubview.show()
    }
    
    func shouldShowTranspatentView() {
        if !self.view.contains(transparentView) {
            view.insertSubview(transparentView, at: view.subviews.count - 1)
            
            NSLayoutConstraint.activate([transparentView.topAnchor.constraint(equalTo: view.topAnchor),
                                         transparentView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                                         transparentView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                                         transparentView.bottomAnchor.constraint(equalTo: view.bottomAnchor)])
        }
    }
    
    func shouldRemoveTranspatentView() {
        transparentView.removeFromSuperview()
    }
}

extension MapViewController: SelectTariffViewDelegate {
    
    func backSubButtonPressed() {
        state = .main
        menuButton.isHidden = false
        cardView.isHidden = false
        personButton.isHidden = false
    }
    
    func promoCodeButtonPressed(_ dismissCallback: ((String?) -> ())?) {
        let view = TariffPromoCodeView()
        view.promoCodeActivetedView.ifPromoCodeIsValidCallback = dismissCallback
        addNewView(view)
    }
    
    func pointsButtonPressed(_ dismissCallback: ((Int?) -> ())?) {
        let view = TariffPointsView()
        view.dismissCallback = dismissCallback
        addNewView(view)
    }
    
    func orderButtonPressed(order: TaxiOrder, tariff: TariffModel) {
        state = .searchForTaxi
        let view = LookingForDriverView()
        view.order = order
        view.tariff = tariff
        view.delegate = self
        addNewView(view)
    }
    
    func confirmOrderButtonPressed() {
        cardView.isHidden = false
        personButton.isHidden = false
        menuButton.isHidden = false
    }
    
    func cencelOrderButtonPressed() {
        state = .main
        let view = CencelTaxiOrderView()
        view.dismissCallback = { [weak self] in
            let vc = CencelTaxiOrderViewController()
            vc.dismissCallback = { [weak self] in
                self?.cardView.isHidden = false
                self?.personButton.isHidden = false
                self?.menuButton.isHidden = false
            }
            
            vc.problemButtonPressedCallback = { [weak self] in
                self?.reportProblemButtonTapped()
            }
            
            let nc = UINavigationController(rootViewController: vc)
            nc.modalTransitionStyle = .crossDissolve
            nc.modalPresentationStyle = .fullScreen
            self?.present(nc, animated: true)
        }
        addNewView(view)
        taxiActiveOrderView.removeFromSuperview()
        isTaxiActiveOrder = false
        isActiveOrder = true
    }
    
    func foundTaxi(order: TaxiOrder, tariff: TariffModel) {
        let orderModel = taxiOrderModelHandler.generateOrder(order: order, tariff: tariff)
        taxiOrderModelHandler.addToTaxiOrder(order: orderModel) { [weak self] in
            DispatchQueue.main.async {
                self?.showTaxiConfirmationView()
            }
        }
    }
    
    func addNewView(_ view: CustromViewProtocol) {
        view.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(view)
        
        NSLayoutConstraint.activate([view.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
                                     view.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
                                     view.topAnchor.constraint(equalTo: self.view.topAnchor),
                                     view.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)])
        view.layoutIfNeeded()
        view.show()
    }
}

extension MapViewController: TariffDelegate {
    func tariffOrderButtonTapped(tariff: TariffModel) {
        toggleSideMenu(hide: true)
        taxiButtonPressed()
    }
}

extension MapViewController: PromotionDetailDelegate {
    func didPromotionSelected(type: PromotionType) {
        toggleSideMenu(hide: true)
        
        switch type {
        case .food:
            foodButtonPressed()
        case .taxi:
            taxiButtonPressed()
        }
    }
}

extension MapViewController: AddAddressViewControllerDelegate {
    func didSelectedAddressAsDestination(address: Address?) {
        if cardView.isTaxiButtonEnable! {
            if !self.view.subviews.contains(addressInputView) {
                taxiButtonPressed()
            }
            
            addressInputView.secondTextView.setText(address?.address)
        } else {
            // show alert taxi already ordered
        }
    }
}

// MARK: - ICartChangesObserver

extension MapViewController: ICartChangesObserver {
    func cartUpdated() {
        DispatchQueue.main.async {
            self.checkCartHasGoods()
        }
    }
}

extension MapViewController: ExpandedActiveOrderViewDelegate {
    func cancelButtonTapped() {
        OrderFoodModelHandler.shared.deleteAllFoodOrders()
        foodActiveOrderView.removeFromSuperview()
        isFoodActiveOrder = false
        isActiveOrder = true
    }
    
    func reportProblemButtonTapped() {
        if let controller = UIStoryboard.init(name: "SupportService", bundle: nil)
            .instantiateViewController(withIdentifier: "SupportID") as? UINavigationController {
            
            controller.modalPresentationStyle = .fullScreen
            controller.modalTransitionStyle = .coverVertical
            present(controller, animated: true)
        }
    }
    
    func addDeliveryButtonTapped() {
        foodButtonPressed()
    }
}

extension MapViewController: CartViewDelegate {
    func foodPaymentButtonTapped(amount: String) {
        hideCart()
        shouldShowTranspatentView()
        let foodPaymentView = FoodPaymentView(amount: amount)
        
        foodPaymentView.dismissFoodPaymentView = { [weak self, weak foodPaymentView] in
            guard let self = self else { return }
            guard let foodPaymentView = foodPaymentView else { return }
            
            foodPaymentView.dismiss() {
                self.shouldRemoveTranspatentView()
                foodPaymentView.removeFromSuperview()
                self.showCart()
            }
        }
        
        foodPaymentView.payButtonAction = { [weak self, weak foodPaymentView] in
            guard let self = self else { return }
            guard let foodPaymentView = foodPaymentView else { return }
            
            foodPaymentView.dismiss() {
                self.shouldRemoveTranspatentView()
                foodPaymentView.removeFromSuperview()
                self.cartView.removeFromSuperview()
                CartModel.shared.emptyCart()
                let thankForOrderView = ThankForOrderView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height + self.view.safeAreaInsets.bottom))
                self.view.addSubview(thankForOrderView)
                self.cardView.isFoodButtonEnable = false
                // record food active order to bd.
            }
        }
        
        view.addSubview(foodPaymentView)
        foodPaymentView.show()
    }
}
