const source = {
  home: "/screenshots/home.png",
  opening: "/screenshots/opening.png",
  library: "/screenshots/library.png",
  privacy: "/screenshots/privacy.png",
};

type SlideProps = {
  id: string;
  theme: "dark" | "light";
  eyebrow: string;
  headline: React.ReactNode;
  subhead: string;
  image: string;
  footer: string;
  accent?: "mint" | "orange" | "blue";
  zoom?: "default" | "controls" | "library";
};

function BrandBar({ theme }: { theme: "dark" | "light" }) {
  return (
    <div className={`brand-bar ${theme}`}>
      <img className="brand-icon" src="/app-icon.png" alt="Hingy" />
      <span className="brand-wordmark">HINGY</span>
      <span className="brand-tag">SOUND FOR EVERY FOLD</span>
    </div>
  );
}

function PhoneFrame({ image, zoom = "default" }: { image: string; zoom?: SlideProps["zoom"] }) {
  return (
    <div className="phone-frame">
      <div className="phone-speaker" />
      <div className={`phone-screen zoom-${zoom}`}>
        <img src={image} alt="Hingy app screen" />
      </div>
    </div>
  );
}

function Slide({ id, theme, eyebrow, headline, subhead, image, footer, accent = "mint", zoom = "default" }: SlideProps) {
  return (
    <section className={`slide ${theme} accent-${accent}`} data-export-slide={id}>
      <BrandBar theme={theme} />
      <div className="copy-block">
        <div className="eyebrow">{eyebrow}</div>
        <h1>{headline}</h1>
        <p>{subhead}</p>
      </div>
      <div className="motif" aria-hidden="true">
        <span />
        <span />
      </div>
      <PhoneFrame image={image} zoom={zoom} />
      <div className="slide-footer">
        <span className="footer-dot" />
        <span>{footer}</span>
      </div>
    </section>
  );
}

export default function Page() {
  return (
    <main className="asset-page">
      <Slide
        id="01-hero"
        theme="dark"
        eyebrow="PERSONAL SOUND"
        headline={<>A little sound.<br />Every fold.</>}
        subhead="Give opening and closing a sound of your own."
        image={source.home}
        footer="Preview build · simulated hinge controls shown"
        accent="mint"
      />
      <Slide
        id="02-two-sides"
        theme="light"
        eyebrow="MAKE IT YOURS"
        headline={<>Choose a sound<br />for each direction.</>}
        subhead="Open with one effect. Close with another. Keep both within reach."
        image={source.opening}
        footer="Opening and closing selections are independent."
        accent="blue"
        zoom="controls"
      />
      <Slide
        id="03-library"
        theme="dark"
        eyebrow="20 ORIGINAL EFFECTS"
        headline={<>Find the sound<br />that fits.</>}
        subhead="Search, preview, and choose from a hand-built library of small sounds."
        image={source.library}
        footer="Crystal selected · preview library"
        accent="orange"
        zoom="library"
      />
      <Slide
        id="04-custom"
        theme="light"
        eyebrow="YOUR CLIP"
        headline={<>Bring your own<br />little sound.</>}
        subhead="Import a short audio clip from Files and tune the effect volume."
        image={source.home}
        footer="Clips up to 5 seconds and 8 MiB."
        accent="mint"
        zoom="controls"
      />
      <Slide
        id="05-private"
        theme="dark"
        eyebrow="LOCAL BY DESIGN"
        headline={<>Private<br />by default.</>}
        subhead="No account. No microphone recording. No analytics SDK. Your choices stay in the app."
        image={source.privacy}
        footer="Review the full privacy summary in-app."
        accent="blue"
      />
    </main>
  );
}
