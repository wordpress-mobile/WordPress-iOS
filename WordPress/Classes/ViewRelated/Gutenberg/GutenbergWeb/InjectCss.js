const injectCss = `
window.injectCss = (css) => {
    const style = document.createElement('style');
    style.innerHTML = css;
    style.type = 'text/css';
    document.head.appendChild(style);
}
`;

const script = document.createElement('script');
script.innerText = injectCss;
script.type = 'text/javascript';
document.head.appendChild(script);
"CSS injection function ready"
