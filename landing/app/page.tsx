import InstallActions from "./install-actions";

const repositoryUrl = "https://github.com/Keith9922/Codex-Theme-Studio";

const steps = [
  ["01", "下载 App", "页面识别系统后，直接下载 macOS 通用版。"],
  ["02", "复制 Skill 链接", "把链接交给能访问 GitHub 和本机文件的编程 AI。"],
  ["03", "描述主题", "AI 制作并导入主题；回到 App 刷新即可切换。"],
];

const themeChips = [
  ["theme-chip-cyber", "赛博霓虹"],
  ["theme-chip-museum", "野生博物"],
  ["theme-chip-paper", "瓷白纸页"],
  ["theme-chip-aurora", "午夜极光"],
];

function Arrow() {
  return <span aria-hidden="true">↗</span>;
}

export default function Home() {
  return (
    <main id="top">
      <div className="ambient ambient-coral" aria-hidden="true" />
      <div className="ambient ambient-mint" aria-hidden="true" />
      <div className="grain" aria-hidden="true" />

      <nav className="nav shell">
        <a className="brand" href="#top" aria-label="Codex Theme Studio 首页">
          <span className="brand-mark" aria-hidden="true"><i /></span>
          <span>CODEX THEME STUDIO</span>
        </a>
        <a className="nav-link" href={repositoryUrl}>
          GitHub <Arrow />
        </a>
      </nav>

      <header className="hero shell">
        <p className="eyebrow">
          <span aria-hidden="true" />
          CODEX DESKTOP THEMES · macOS
        </p>
        <div className="title-mask">
          <h1>给 Codex 换个主题。</h1>
        </div>
        <p className="hero-lead">
          下载 App 管理主题。复制 Skill 链接给 AI，让它帮你制作并导入新的主题。
        </p>
        <InstallActions />
        <div className="theme-chips" aria-label="主题示例">
          {themeChips.map(([className, name]) => (
            <span className={`theme-chip ${className}`} key={name}>{name}</span>
          ))}
        </div>
      </header>

      <section className="product-stage shell" aria-label="Codex Theme Studio 应用预览">
        <div className="stage-heading">
          <div>
            <span>THEME WORKBENCH</span>
            <strong>预览、搜索、刷新、切换。</strong>
          </div>
          <p>原生 macOS App</p>
        </div>
        <div className="preview">
          <div className="window-bar" aria-hidden="true">
            <span /><span /><span />
            <i>Codex Theme Studio</i>
          </div>
          {/* Static rendering avoids a host-specific image optimizer dependency. */}
          {/* eslint-disable-next-line @next/next/no-img-element */}
          <img
            src="/app-preview.png"
            alt="Codex Theme Studio macOS 工作台，展示主题预览、搜索和切换"
            width="2880"
            height="1800"
          />
          <div className="preview-shine" aria-hidden="true" />
        </div>
        <div className="floating-pill floating-pill-left" aria-hidden="true">
          <i /> 主题已载入
        </div>
        <div className="floating-pill floating-pill-right" aria-hidden="true">
          ↻ 运行中热切换
        </div>
      </section>

      <section className="feature-band">
        <div className="shell feature-list">
          <span>主题预览与搜索</span>
          <span>刷新本机主题</span>
          <span>运行中热切换</span>
          <span>可选开机启动</span>
        </div>
      </section>

      <section className="section shell steps-section" id="use">
        <div className="section-title reveal">
          <span>使用方法</span>
          <h2>从下载到换好，三步。</h2>
        </div>
        <div className="steps reveal">
          {steps.map(([number, title, body]) => (
            <article key={number}>
              <span>{number}</span>
              <h3>{title}</h3>
              <p>{body}</p>
            </article>
          ))}
        </div>
      </section>

      <section className="section shell notes reveal" id="notes">
        <div className="section-title">
          <span>使用前请了解</span>
          <h2>必要说明。</h2>
        </div>
        <div className="note-list">
          <p><strong>非官方项目。</strong>本项目与 OpenAI 无隶属、授权、赞助或背书关系。</p>
          <p><strong>首次打开。</strong>App 尚未 Apple 公证；若被 macOS 拦截，请在 Finder 中右键选择“打开”。</p>
          <p><strong>工作方式。</strong>主题通过本机调试接口加载，不修改官方 Codex App。启用期间不要运行来源不明的本机程序。</p>
          <p><strong>图片与隐私。</strong>App 在本机管理主题；让 AI 处理图片时，内容可能按所用 AI 服务的规则发送给该服务。</p>
          <p><strong>素材权利。</strong>使用角色、真人或第三方素材时，请自行确认生成、使用与公开分享的权利。</p>
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
