
import SwiftUI

struct ContentView: View {

    @State private var isConnected = false
    @State private var isChecking = false
    @State private var hasChecked = false

    private func checkConnection() {
        isChecking = true

        BridgeXStatusClient.shared().checkStatus { connected in
            DispatchQueue.main.async {
                isConnected = connected
                isChecking = false
                hasChecked = true
            }
        }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    // App identity
                    VStack(alignment: .leading, spacing: 8) {
                        Text("BridgeX")
                            .font(.system(size: 34, weight: .bold))

                        Text("Your iPhone connectivity dashboard")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    // Live connection status
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Label("TWEAK CONNECTION", systemImage: "iphone")
                                .font(.caption.weight(.bold))
                                .foregroundColor(.secondary)

                            Spacer()

                            Text(isChecking ? "CHECKING..." :
                                    (isConnected ? "CONNECTED" : "NOT CONNECTED"))
                                .font(.caption2.weight(.bold))
                                .foregroundColor(
                                    isChecking ? .orange :
                                        (isConnected ? .green : .orange)
                                )
                        }

                        HStack(spacing: 14) {
                            Image(systemName: "iphone")
                                .font(.system(size: 34))
                                .foregroundColor(.accentColor)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(
                                    isChecking ? "Checking BridgeX..." :
                                        (isConnected ? "BridgeX is responding" :
                                            "No response from BridgeX")
                                )
                                .font(.headline)

                                Text(
                                    isConnected
                                    ? "SpringBoard successfully responded to the app."
                                    : "Waiting for a response from the SpringBoard tweak."
                                )
                                .font(.caption)
                                .foregroundColor(.secondary)
                            }
                        }

                        Button(action: checkConnection) {
                            HStack {
                                Image(systemName: "arrow.clockwise")
                                Text("Check Connection")
                            }
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .disabled(isChecking)
                        .opacity(isChecking ? 0.6 : 1)
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(16)

                    // Tweak status
                    VStack(alignment: .leading, spacing: 12) {
                        Text("TWEAK STATUS")
                            .font(.caption.weight(.bold))
                            .foregroundColor(.secondary)

                        HStack {
                            Label(
                                "BridgeX Foundation",
                                systemImage: isConnected
                                    ? "checkmark.circle.fill"
                                    : "exclamationmark.circle.fill"
                            )
                            .font(.subheadline.weight(.medium))

                            Spacer()

                            Text(isConnected ? "ACTIVE" : "UNCONFIRMED")
                                .font(.caption2.weight(.bold))
                                .foregroundColor(isConnected ? .green : .orange)
                        }

                        Text(
                            isConnected
                            ? "Live communication with the SpringBoard tweak verified."
                            : "The app has not received a valid response from the tweak."
                        )
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(16)

                    // Features
                    VStack(alignment: .leading, spacing: 12) {
                        Text("FEATURES")
                            .font(.caption.weight(.bold))
                            .foregroundColor(.secondary)

                        FeatureRow(
                            icon: "car",
                            title: "CarPlay Integration",
                            subtitle: "Core functionality in development",
                            status: "COMING SOON"
                        )

                        Divider()

                        FeatureRow(
                            icon: "app.badge",
                            title: "App Compatibility",
                            subtitle: "Manage supported applications",
                            status: "PLANNED"
                        )

                        Divider()

                        FeatureRow(
                            icon: "gearshape",
                            title: "Tweak Settings",
                            subtitle: "Configure BridgeX preferences",
                            status: "PLANNED"
                        )
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(16)

                    // Version
                    HStack {
                        Text("BridgeX")
                        Spacer()
                        Text("Version 0.1.0")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                .padding()
            }
            .navigationBarHidden(true)
            .background(Color(.systemBackground))
        }
        .onAppear {
            checkConnection()
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let status: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.accentColor)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))

                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text(status)
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
