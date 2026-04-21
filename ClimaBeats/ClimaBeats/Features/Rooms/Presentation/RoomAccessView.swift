import SwiftUI

struct RoomAccessHostView: View {
    @StateObject private var viewModel: RoomAccessViewModel

    init() {
        let repository = FirestoreRoomRepository()
        let realtimeSync = FirestoreRoomRealtimeSync()
        let lifecycleUseCase = RoomLifecycleUseCase(repository: repository, realtimeSync: realtimeSync)
        _viewModel = StateObject(wrappedValue: RoomAccessViewModel(lifecycleUseCase: lifecycleUseCase))
    }

    var body: some View {
        RoomAccessView(viewModel: viewModel)
    }
}

struct RoomAccessView: View {
    @ObservedObject var viewModel: RoomAccessViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                if let room = viewModel.currentRoom {
                    RoomSessionHostView(room: room) {
                        viewModel.leaveRoom()
                    }
                } else {
                    if let myRoom = viewModel.myHostedRoom {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("My Room")
                                .font(.subheadline)
                                .bold()
                            Text("Code: \(myRoom.code)")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Button("Open My Room") {
                                viewModel.openMyHostedRoom()
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(viewModel.isLoading)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    Picker("Mode", selection: $viewModel.mode) {
                        ForEach(RoomAccessViewModel.Mode.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)

                    TextField("Display name", text: $viewModel.displayNameInput)
                        .textFieldStyle(.roundedBorder)

                    if viewModel.mode == .create {
                        Picker("Weather Source", selection: $viewModel.selectedWeatherMode) {
                            Text("Host Location").tag(RoomWeatherSourceMode.hostLocation)
                            Text("Selected City").tag(RoomWeatherSourceMode.selectedCity)
                        }
                        .pickerStyle(.segmented)

                        if viewModel.selectedWeatherMode == .selectedCity {
                            TextField("City", text: $viewModel.selectedCity)
                                .textFieldStyle(.roundedBorder)
                        }
                    } else {
                        TextField("Room code", text: $viewModel.roomCodeInput)
                            .textFieldStyle(.roundedBorder)
                            .textInputAutocapitalization(.characters)
                            .autocorrectionDisabled()
                    }

                    Button(viewModel.mode == .create ? "Create Room" : "Join Room") {
                        viewModel.submit()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(viewModel.isLoading)

                    if viewModel.isLoading {
                        ProgressView("Please wait...")
                    }
                }

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                Spacer()
            }
            .padding()
            .onAppear {
                viewModel.loadMyHostedRoom()
            }
            .navigationTitle("Social Rooms")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") { dismiss() }
                }
            }
        }
    }
}
