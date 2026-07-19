import InstallActions from "./install-actions";

const repositoryUrl = "https://github.com/Keith9922/Codex-Theme-Studio";

const steps = [
  {
    number: "01",
    title: "下载 App",
    body: "页面会识别当前系统。macOS 用户点击按钮后直接下载安装包。",
  },
  {
    number: "02",
    title: "把链接发给 AI",
    body: "复制 Theme Skill 链接，交给 Codex 或其他能访问 GitHub 的编程 AI。",
  },
  {
    number: "03",
    title: "描述你想要的主题",
    body: "AI 会安装 Skill、制作主题并导入。回到 App 刷新后即可切换。",
  },
];

const features = ["主题预览与搜索", "刷新本机主题", "运行中热切换", "可选开机启动"];

function Arrow() {
  return <span aria-hidden="true">↗</span>;
}

export default function Home() {
  return (
    <main id="top">
      <nav className="nav shell" aria-label="主导航">
        <a className="brand" href="#top" aria-label="Codex Theme Studio 首页">
          <span className="brand-mark" aria-hidden="true">●</span>
          <span>CODEX THEME STUDIO</span>
        </a>
        <a className="nav-link" href={repositoryUrl}>
          GitHub <Arrow />
        </a>
      </nav>

      <header className="hero shell">
        <div className="hero-copy">
          <p className="eyebrow">CODEX DESKTOP THEMES · macOS</p>
          <h1>给 Codex<br />换个主题。</h1>
          <p className="hero-lead">
            下载 App 管理主题。复制 Skill 链接给 AI，让它帮你制作并导入新的主题。
          </p>
        </div>
        <InstallActions />
      </header>

      <section className="preview shell" aria-label="Codex Theme Studio 应用预览">
        <div className="window-bar" aria-hidden="true"><span /><span /><span /></div>
        {/* The static asset avoids relying on the host-specific image optimizer. */}
        {/* eslint-disable-next-line @next/next/no-img-element */}
        <img
          src="/app-preview.png"
          alt="Codex Theme Studio macOS 工作台，展示主题预览、搜索和切换"
          width="2880"
          height="1800"
        />
      </section>

      <section className="section shell" id="use">
        <div className="section-title">
          <span>使用方法</span>
          <h2>三步就够了。</h2>
        </div>
        <div className="steps">
          {steps.map((step) => (
            <article key={step.number}>
              <span>{step.number}</span>
              <h3>{step.title}</h3>
              <p>{step.body}</p>
            </article>
          ))}
        </div>
      </section>

      <section className="feature-band">
        <div className="shell feature-list">
          {features.map((feature) => <span key={feature}>{feature}</span>)}
        </div>
      </section>

      <section className="section shell notes" id="notes">
        <div className="section-title">
          <span>使用前请了解</span>
          <h2>必要说明。</h2>
        </div>
        <div className="note-list">
          <p>
            <strong>非官方项目。</strong>
            本项目与 OpenAI 无隶属、授权、赞助或背书关系。
          </p>
          <p>
            <strong>首次打开。</strong>
            App 采用 ad-hoc 签名且尚未 Apple 公证；若被 macOS 拦截，请在 Finder 中右键选择“打开”。
          </p>
          <p>
            <strong>工作方式。</strong>
            主题通过本机调试接口加载，不修改官方 Codex App。启用期间不要运行来源不明的本机程序。
          </p>
          <p>
            <strong>图片与隐私。</strong>
            App 在本机管理主题；让 AI 生成或处理图片时，内容可能按你所用 AI 服务的规则发送给该服务。
          </p>
          <p>
            <strong>素材权利。</strong>
            使用角色、真人或第三方素材时，请自行确认生成、使用与公开分享的权利。
          </p>
        </div>
      </section>

      <footer>
        <div className="shell footer-inner">
          <div>
            <strong>CODEX THEME STUDIO</strong>
            <p>macOS 13+ · Apple Silicon 与 Intel</p>
          </div>
          <div className="footer-links">
            <a href={repositoryUrl}>GitHub</a>
            <a href={`${repositoryUrl}/blob/main/macos/README.md`}>使用文档</a>
            <a href={`${repositoryUrl}/blob/main/macos/LICENSE`}>MIT License</a>
          </div>
        </div>
      </footer>
    </main>
  );
}
