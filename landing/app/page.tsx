import Image from "next/image";

const releaseUrl =
  "https://github.com/Keith9922/Codex-Theme-Studio/releases/latest";
const repositoryUrl = "https://github.com/Keith9922/Codex-Theme-Studio";
const skillUrl =
  "https://github.com/Keith9922/Codex-Theme-Studio/blob/main/skills/create-codex-theme/README.md";
const configUrl =
  "https://github.com/Keith9922/Codex-Theme-Studio/blob/main/skills/create-codex-theme/config/product.json";

const workflow = [
  {
    number: "01",
    title: "安装 App 与 Skill",
    body: "下载 Codex Theme Studio，把 create-codex-theme 文件夹放进 Codex Skills 目录。",
    detail: "~/.codex/skills/create-codex-theme",
  },
  {
    number: "02",
    title: "只说一句话",
    body: "描述颜色、氛围、人物、构图和是否立即应用。Skill 会先搜索，再生成、校验并安装。",
    detail: "无需手写 JSON 或整理图片目录",
  },
  {
    number: "03",
    title: "刷新，随意切换",
    body: "打开工作台或点击“刷新皮肤”，新主题会出现在主题库中。保留多套主题，随时热切换。",
    detail: "生成和安装默认不会重启 Codex",
  },
];

const capabilities = [
  ["一句话制皮", "自然语言描述颜色、氛围、人物与构图"],
  ["自动安装", "生成后写入统一的本机主题库"],
  ["多主题管理", "搜索、分类、预览、刷新和热切换"],
  ["开机恢复", "登录启动与普通启动后的单次接管"],
  ["本地优先", "主题图片留在本机，不自动上传"],
  ["官方应用零改动", "不拆包、不修改 app.asar 或代码签名"],
];

const faqs = [
  [
    "真的只需要输入一句话吗？",
    "是。安装 App 和 Skill 后，直接描述想要的主题即可。Skill 会先搜索已有主题；没有匹配项时再生成、校验并安装。",
  ],
  [
    "生成后为什么 App 能直接识别？",
    "Skill 按统一主题包规范把结果安装到本机主题库。App 打开工作台或点击“刷新皮肤”时会重新扫描这个目录。",
  ],
  [
    "可以保留和切换多少套主题？",
    "没有人为设置的数量上限。每套主题使用独立目录，App 会将有效主题集中展示并支持活动会话热切换。",
  ],
  [
    "会修改官方 Codex 吗？",
    "不会修改官方 App、app.asar 或签名。主题通过仅监听 127.0.0.1 的本机 CDP 会话加载。",
  ],
];

function Arrow() {
  return <span aria-hidden="true">↗</span>;
}

export default function Home() {
  return (
    <main>
      <nav className="nav shell" aria-label="主导航">
        <a className="brand" href="#top" aria-label="Codex Theme Studio 首页">
          <span className="brand-mark" aria-hidden="true">●</span>
          <span>CODEX THEME STUDIO</span>
        </a>
        <div className="nav-links">
          <a href="#how">使用方法</a>
          <a href="#config">产品配置</a>
          <a href="#statements">声明</a>
        </div>
        <a className="nav-cta" href={repositoryUrl}>
          GitHub <Arrow />
        </a>
      </nav>

      <section className="hero shell" id="top">
        <div className="hero-copy">
          <div className="eyebrow">
            <span className="pulse" />
            APP + SKILL · LOCAL FIRST
          </div>
          <h1>
            一句话，
            <br />
            给 Codex 换一个
            <span>完整世界。</span>
          </h1>
          <p className="hero-lead">
            下载 Skill，描述你想要的主题。生成、校验和安装完成后，
            Codex Theme Studio 会直接识别，并让你在多套皮肤之间自由切换。
          </p>
          <div className="hero-actions">
            <a className="button primary" href={releaseUrl}>
              下载 macOS App <Arrow />
            </a>
            <a className="button secondary" href={skillUrl}>
              获取制皮 Skill
            </a>
          </div>
          <div className="compatibility">
            <span>macOS 13+</span>
            <span>Apple Silicon + Intel</span>
            <span>不修改官方 App</span>
          </div>
        </div>

        <div className="hero-product" aria-label="产品工作流示意">
          <div className="prompt-card">
            <div className="prompt-topline">
              <span>NEW THEME REQUEST</span>
              <span className="online">READY</span>
            </div>
            <p>
              <span className="prompt-symbol">$</span>
              create-codex-theme 做一套低饱和森林主题，左侧留白，生成后安装，暂时不要应用。
            </p>
            <div className="generation-log">
              <span><i>✓</i> 搜索本机主题</span>
              <span><i>✓</i> 生成与安全校验</span>
              <span><i>✓</i> 安装到主题库</span>
            </div>
          </div>
          <div className="mini-library">
            <div className="mini-header">
              <div>
                <small>THEME LIBRARY</small>
                <strong>15 套主题，随时切换</strong>
              </div>
              <span>刷新皮肤 ↻</span>
            </div>
            <div className="theme-strip" aria-hidden="true">
              <div className="theme-a"><b>赛博霓虹</b></div>
              <div className="theme-b"><b>野生博物</b></div>
              <div className="theme-c"><b>午夜极光</b></div>
            </div>
          </div>
        </div>
      </section>

      <section className="proof-bar">
        <div className="shell proof-grid">
          <div><strong>1</strong><span>句话开始</span></div>
          <div><strong>0</strong><span>官方文件修改</span></div>
          <div><strong>∞</strong><span>本机主题切换</span></div>
          <div><strong>127.0.0.1</strong><span>CDP 监听范围</span></div>
        </div>
      </section>

      <section className="section shell" id="how">
        <div className="section-heading">
          <div>
            <span className="kicker">HOW IT WORKS</span>
            <h2>从一句话到主题库，只有三步。</h2>
          </div>
          <p>
            Skill 负责理解、生成和安装；App 负责发现、管理和切换。
            两者共享同一份本机主题规范。
          </p>
        </div>
        <div className="workflow-grid">
          {workflow.map((item) => (
            <article className="workflow-card" key={item.number}>
              <span className="step-number">{item.number}</span>
              <h3>{item.title}</h3>
              <p>{item.body}</p>
              <code>{item.detail}</code>
            </article>
          ))}
        </div>
        <div className="example-prompt">
          <span>直接复制这句话试试</span>
          <code>
            $create-codex-theme 做一套黑紫青的赛博主题，主体靠右，生成后安装并让我在 App 里选择。
          </code>
        </div>
      </section>

      <section className="section showcase">
        <div className="shell showcase-grid">
          <div className="showcase-copy">
            <span className="kicker">NATIVE WORKBENCH</span>
            <h2>生成不是终点。管理起来才算产品。</h2>
            <p>
              新主题会进入统一主题库。你可以搜索、筛选、预览、刷新，
              并在 Codex 已运行时热切换，不再反复注入和重启。
            </p>
            <ul>
              <li>打开工作台时自动扫描主题</li>
              <li>显式“刷新皮肤”按钮寻找新资产</li>
              <li>纯色、氛围、人物和自定义分类</li>
              <li>登录启动、自动打开与单次接管</li>
            </ul>
          </div>
          <div className="app-frame">
            <div className="window-bar"><span /><span /><span /></div>
            <Image
              src="/app-preview.png"
              alt="Codex Theme Studio 原生 macOS 工作台，展示赛博霓虹主题和主题库"
              width={2880}
              height={1800}
              priority
            />
          </div>
        </div>
      </section>

      <section className="section shell" id="config">
        <div className="section-heading config-heading">
          <div>
            <span className="kicker">ONE CONFIG</span>
            <h2>一份配置，约定 App 与 Skill 如何协作。</h2>
          </div>
          <a className="text-link" href={configUrl}>
            查看 product.json <Arrow />
          </a>
        </div>
        <div className="config-panel">
          <div className="config-code">
            <div className="code-title">
              <span>config/product.json</span>
              <span>schema v1</span>
            </div>
            <pre>{`{
  "skill": "create-codex-theme",
  "installAfterGenerate": true,
  "applyAfterGenerate": false,
  "restartCodex": false,
  "multipleThemes": true,
  "themeLibrary": "~/Library/Application Support/…/themes"
}`}</pre>
          </div>
          <div className="config-explain">
            <h3>默认行为是“生成并安装，但不打扰”。</h3>
            <p>
              Skill 默认先搜索已有主题；没有合适结果才生成。完成后自动安装，
              但不会擅自应用或重启 Codex。只有用户明确说“现在应用”时才执行切换。
            </p>
            <div className="config-tags">
              <span>先搜索</span>
              <span>自动安装</span>
              <span>默认不应用</span>
              <span>默认不重启</span>
            </div>
          </div>
        </div>
      </section>

      <section className="section feature-section shell">
        <span className="kicker">PRODUCT CAPABILITIES</span>
        <h2>把一次性的换图脚本，变成长期可用的主题产品。</h2>
        <div className="capability-grid">
          {capabilities.map(([title, body], index) => (
            <article key={title}>
              <span>{String(index + 1).padStart(2, "0")}</span>
              <h3>{title}</h3>
              <p>{body}</p>
            </article>
          ))}
        </div>
      </section>

      <section className="section statement-section" id="statements">
        <div className="shell">
          <div className="section-heading">
            <div>
              <span className="kicker">IMPORTANT NOTES</span>
              <h2>必要声明，写在使用之前。</h2>
            </div>
            <p>开放、透明，也尊重官方应用、用户数据和素材权利。</p>
          </div>
          <div className="statement-grid">
            <article>
              <strong>非官方项目</strong>
              <p>本项目与 OpenAI 无隶属、授权、赞助或背书关系。Codex 及相关商标归其权利人所有。</p>
            </article>
            <article>
              <strong>本机 CDP 边界</strong>
              <p>CDP 只监听 127.0.0.1，但调试端口本身具有较高权限。启用主题期间不要运行来源不明的本机程序。</p>
            </article>
            <article>
              <strong>签名与公证</strong>
              <p>公开 App 使用 ad-hoc 签名、尚未 Apple 公证。首次打开可能需要在 Finder 中右键选择“打开”。</p>
            </article>
            <article>
              <strong>素材与 IP</strong>
              <p>生成受版权保护的角色、真人或第三方素材时，请确认个人使用与再分发权利。私人主题不会自动进入公开 Release。</p>
            </article>
            <article>
              <strong>隐私与上传</strong>
              <p>主题图片和配置保存在本机。项目不会主动上传主题图片，也不会改写 API Key 或模型供应商设置。</p>
            </article>
            <article>
              <strong>兼容性</strong>
              <p>原生工作台需要 macOS 13+ 与官方 Codex Desktop。Universal 2 构建支持 Apple Silicon 和 Intel Mac。</p>
            </article>
          </div>
        </div>
      </section>

      <section className="section shell faq-section">
        <span className="kicker">FAQ</span>
        <h2>开始之前，你可能还想知道。</h2>
        <div className="faq-list">
          {faqs.map(([question, answer]) => (
            <details key={question}>
              <summary>{question}<span>＋</span></summary>
              <p>{answer}</p>
            </details>
          ))}
        </div>
      </section>

      <section className="final-cta shell">
        <span className="kicker">READY TO THEME</span>
        <h2>下一套主题，从一句话开始。</h2>
        <p>先安装 App，再把 Skill 放进 Codex。剩下的交给你的描述。</p>
        <div className="hero-actions">
          <a className="button primary" href={releaseUrl}>
            下载 App 与 Skill <Arrow />
          </a>
          <a className="button secondary" href={repositoryUrl}>
            查看 GitHub
          </a>
        </div>
      </section>

      <footer>
        <div className="shell footer-inner">
          <div>
            <strong>CODEX THEME STUDIO</strong>
            <p>Local themes for the official Codex Desktop app.</p>
          </div>
          <div className="footer-links">
            <a href={releaseUrl}>Releases</a>
            <a href={skillUrl}>Skill</a>
            <a href={`${repositoryUrl}/blob/main/macos/LICENSE`}>MIT License</a>
          </div>
        </div>
      </footer>
    </main>
  );
}
