// The dedicated AppStore configuration must never compile the simulation-only adapter.
// SDK compilation alone does not establish hardware validation; the build phase
// also runs the evidence-based submission checker for this configuration.
#if APP_STORE_RELEASE && !DUO_HINGE_SDK
#error("App Store builds require the public Duo hinge SDK. Do not submit the preview as a physical-fold utility.")
#endif
