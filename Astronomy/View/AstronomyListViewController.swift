//
//  AstronomyListViewController.swift
//  Astronomy
//
//  Created by gagan joshi on 2024-10-12.
//

import UIKit

class AstronomyListViewController: UIViewController {
    
    let tableView: UITableView = {
        let tableView = UITableView()
        tableView.tableFooterView = UIView()
        tableView.separatorStyle = .singleLine
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        tableView.showsVerticalScrollIndicator = false
        tableView.showsHorizontalScrollIndicator = false
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()
    
    let stackView = UIStackView()
    
    private var viewModel = AstronomyListViewModel()
    
    struct Constants {
        static let Astronomy_ROW_CELL_ID = "astronomy_row_cell_identifier"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationController?.navigationItem.largeTitleDisplayMode = .always
        
        setupView()
    }
    
    private func setupView() {
        
        self.view.backgroundColor = .systemBackground
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 8
        
        stackView.addArrangedSubview(tableView)
        
        view.addAutolayoutSubview(stackView)
        view.pinToEdges(stackView)
        
        
        tableView.register(AstronomyRowCell.self, forCellReuseIdentifier: Constants.Astronomy_ROW_CELL_ID)
        tableView.delegate = self
        tableView.dataSource = self
        viewModel.delegate = self
        title = "Astronomies"
        
        Task { [weak self] in
            await self?.viewModel.loadAstronomy()
        }
        
             
    }
}

extension AstronomyListViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.astronomies.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: Constants.Astronomy_ROW_CELL_ID, for: indexPath) as? AstronomyRowCell else {
            return UITableViewCell()
        }
        let astronomy = viewModel.astronomies[indexPath.row]
        cell.astronomy = astronomy
        
        if astronomy.mediaType == "image" {
            if astronomy.image == nil {
                viewModel.downloadImage(for: indexPath, astronomy: astronomy)
            }
        } 
       
        return cell
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        let astronomy = viewModel.astronomies[indexPath.row]
        print(astronomy)
        let detailViewModel = AstronomyDetailsViewModel(astronomy: astronomy)
        let detailViewController = AstronomyDetailsViewController(viewModel: detailViewModel)
        navigationController?.pushViewController(detailViewController, animated: true)
    }
}

// View Model Delegate
extension AstronomyListViewController: AstronomyListViewModelDelegate {
    func didUpdateImage(for indexpath: IndexPath,image: UIImage) {
        if let cell = tableView.cellForRow(at: indexpath) as? AstronomyRowCell {
            cell.setImage(image)
            print("image updated at \(indexpath.row)")
        }
    }
    
    func didUpdateAstronomies() {
        print("reloadTable")
        //viewModel = sender
        tableView.reloadData()
    }
}



