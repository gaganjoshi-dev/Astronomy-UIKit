//
//  AstronomyListViewController.swift
//  Astronomy
//

import UIKit

final class AstronomyListViewController: UIViewController {

    private enum Section: Hashable {
        case main
    }

    private enum Constants {
        static let rowCellID = "astronomy_row_cell_identifier"
    }

    private let tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.separatorStyle = .singleLine
        tableView.separatorInset = .zero
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()

    private let bannerLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .footnote)
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        label.textAlignment = .center
        label.isHidden = true
        return label
    }()

    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()

    private let footerSpinner: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        indicator.startAnimating()
        return indicator
    }()

    private let endOfFeedLabel: UILabel = {
        let label = UILabel()
        label.text = "You're all caught up"
        label.font = .preferredFont(forTextStyle: .footnote)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        return label
    }()

    private let viewModel: AstronomyListViewModel

    private lazy var feedDataSource: UITableViewDiffableDataSource<Section, String> = {
        UITableViewDiffableDataSource<Section, String>(tableView: tableView) { [weak self] tableView, indexPath, date in
            guard
                let self,
                let cell = tableView.dequeueReusableCell(
                    withIdentifier: Constants.rowCellID,
                    for: indexPath
                ) as? AstronomyRowCell,
                let astronomy = viewModel.astronomy(withDate: date)
            else {
                return UITableViewCell()
            }

            cell.configure(with: astronomy)

            if astronomy.isImage, astronomy.image == nil {
                viewModel.loadImage(for: astronomy)
            }

            return cell
        }
    }()

    init(repository: any AstronomyRepositoryProtocol) {
        self.viewModel = AstronomyListViewModel(repository: repository)
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Astronomies"
        navigationItem.largeTitleDisplayMode = .always
        setupView()
        Task { await viewModel.refresh() }
    }

    private func setupView() {
        view.backgroundColor = .systemBackground

        // Pin table edge-to-edge so large titles collapse on scroll.
        view.addAutolayoutSubview(tableView)
        view.addAutolayoutSubview(loadingIndicator)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])

        setupBannerHeader()

        tableView.register(AstronomyRowCell.self, forCellReuseIdentifier: Constants.rowCellID)
        tableView.delegate = self
        tableView.prefetchDataSource = self
        viewModel.delegate = self

        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshPulled), for: .valueChanged)
        tableView.refreshControl = refreshControl

        updateTableFooter(loading: false, atEnd: false)
    }

    private func setupBannerHeader() {
        let container = UIView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: 1))
        bannerLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(bannerLabel)
        NSLayoutConstraint.activate([
            bannerLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: 4),
            bannerLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            bannerLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            bannerLabel.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -4)
        ])
        container.layoutIfNeeded()
        let height = bannerLabel.isHidden ? 0 : container.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
        container.frame.size.height = max(height, bannerLabel.isHidden ? 0 : 1)
        tableView.tableHeaderView = container
    }

    private func updateBannerHeaderVisibility() {
        guard let container = tableView.tableHeaderView else { return }
        container.isHidden = bannerLabel.isHidden
        let width = tableView.bounds.width
        bannerLabel.preferredMaxLayoutWidth = width - 32
        container.frame.size.width = width
        container.setNeedsLayout()
        container.layoutIfNeeded()
        let height = bannerLabel.isHidden ? 0 : container.systemLayoutSizeFitting(
            CGSize(width: width, height: 0),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        ).height
        container.frame.size.height = height
        tableView.tableHeaderView = container
    }

    private func applySnapshot(animatingDifferences: Bool) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, String>()
        snapshot.appendSections([.main])
        snapshot.appendItems(viewModel.astronomies.map(\.date), toSection: .main)
        feedDataSource.apply(snapshot, animatingDifferences: animatingDifferences)
    }

    private func updateTableFooter(loading: Bool, atEnd: Bool) {
        if loading {
            let container = UIView(frame: CGRect(x: 0, y: 0, width: tableView.bounds.width, height: 56))
            footerSpinner.center = CGPoint(x: container.bounds.midX, y: container.bounds.midY)
            container.addSubview(footerSpinner)
            tableView.tableFooterView = container
        } else if atEnd {
            let container = UIView(frame: CGRect(x: 0, y: 0, width: tableView.bounds.width, height: 44))
            endOfFeedLabel.frame = container.bounds
            container.addSubview(endOfFeedLabel)
            tableView.tableFooterView = container
        } else {
            tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 16))
        }
    }

    @objc private func refreshPulled() {
        Task {
            await viewModel.refresh()
            tableView.refreshControl?.endRefreshing()
        }
    }
}

extension AstronomyListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        viewModel.loadNextPageIfNeeded(currentRow: indexPath.row)
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard
            let date = feedDataSource.itemIdentifier(for: indexPath),
            let astronomy = viewModel.astronomy(withDate: date)
        else { return }

        let detailViewModel = AstronomyDetailsViewModel(astronomy: astronomy)
        let detailViewController = AstronomyDetailsViewController(viewModel: detailViewModel)
        navigationController?.pushViewController(detailViewController, animated: true)
    }
}

extension AstronomyListViewController: UITableViewDataSourcePrefetching {
    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        guard let maxRow = indexPaths.map(\.row).max() else { return }
        viewModel.loadNextPageIfNeeded(currentRow: maxRow)
    }
}

extension AstronomyListViewController: AstronomyListViewModelDelegate {
    func didUpdateFeed(animatingDifferences: Bool) {
        applySnapshot(animatingDifferences: animatingDifferences)
    }

    func didUpdateImage(for date: String, image: UIImage) {
        guard let row = viewModel.astronomies.firstIndex(where: { $0.date == date }) else { return }
        let indexPath = IndexPath(row: row, section: 0)
        guard let cell = tableView.cellForRow(at: indexPath) as? AstronomyRowCell else { return }
        cell.setImage(image)
    }

    func didUpdateLoadingState() {
        switch viewModel.loadingState {
        case .loading:
            loadingIndicator.startAnimating()
        case .idle, .loaded:
            loadingIndicator.stopAnimating()
        case .failed(let message):
            loadingIndicator.stopAnimating()
            presentError(message)
        }
    }

    func didUpdateLoadingMore(_ isLoading: Bool) {
        updateTableFooter(loading: isLoading, atEnd: !viewModel.hasMorePages && !isLoading)
    }

    func didUpdateEndOfFeed(_ isAtEnd: Bool) {
        guard viewModel.loadingState != .loading else { return }
        if case .failed = viewModel.loadingState {
            updateTableFooter(loading: false, atEnd: false)
            return
        }
        if !viewModel.isLoadingMore {
            updateTableFooter(loading: false, atEnd: isAtEnd && !viewModel.astronomies.isEmpty)
        }
    }

    func didUpdateDataSourceBanner(message: String?) {
        if let message {
            bannerLabel.text = message
            bannerLabel.isHidden = false
        } else {
            bannerLabel.text = nil
            bannerLabel.isHidden = true
        }
        updateBannerHeaderVisibility()
    }

    private func presentError(_ message: String) {
        let alert = UIAlertController(
            title: "Unable to Load",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Retry", style: .default) { [weak self] _ in
            Task { await self?.viewModel.refresh() }
        })
        alert.addAction(UIAlertAction(title: "OK", style: .cancel))
        present(alert, animated: true)
    }
}
