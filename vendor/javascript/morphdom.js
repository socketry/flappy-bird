var e=11;function morphAttrs(r,t){var a=t.attributes;var n;var o;var i;var d;var l;if(t.nodeType!==e&&r.nodeType!==e){for(var u=a.length-1;u>=0;u--){n=a[u];o=n.name;i=n.namespaceURI;d=n.value;if(i){o=n.localName||o;l=r.getAttributeNS(i,o);if(l!==d){n.prefix==="xmlns"&&(o=n.name);r.setAttributeNS(i,o,d)}}else{l=r.getAttribute(o);l!==d&&r.setAttribute(o,d)}}var f=r.attributes;for(var v=f.length-1;v>=0;v--){n=f[v];o=n.name;i=n.namespaceURI;if(i){o=n.localName||o;t.hasAttributeNS(i,o)||r.removeAttributeNS(i,o)}else t.hasAttribute(o)||r.removeAttribute(o)}}}var r;var t="http://www.w3.org/1999/xhtml";var a=typeof document==="undefined"?void 0:document;var n=!!a&&"content"in a.createElement("template");var o=!!a&&a.createRange&&"createContextualFragment"in a.createRange();function createFragmentFromTemplate(e){var r=a.createElement("template");r.innerHTML=e;return r.content.childNodes[0]}function createFragmentFromRange(e){if(!r){r=a.createRange();r.selectNode(a.body)}var t=r.createContextualFragment(e);return t.childNodes[0]}function createFragmentFromWrap(e){var r=a.createElement("body");r.innerHTML=e;return r.childNodes[0]}
/**
 * This is about the same
 * var html = new DOMParser().parseFromString(str, 'text/html');
 * return html.body.firstChild;
 *
 * @method toElement
 * @param {String} str
 */function toElement(e){e=e.trim();return n?createFragmentFromTemplate(e):o?createFragmentFromRange(e):createFragmentFromWrap(e)}
/**
 * Returns true if two node's names are the same.
 *
 * NOTE: We don't bother checking `namespaceURI` because you will never find two HTML elements with the same
 *       nodeName and different namespace URIs.
 *
 * @param {Element} a
 * @param {Element} b The target element
 * @return {boolean}
 */function compareNodeNames(e,r){var t=e.nodeName;var a=r.nodeName;var n,o;if(t===a)return true;n=t.charCodeAt(0);o=a.charCodeAt(0);return n<=90&&o>=97?t===a.toUpperCase():o<=90&&n>=97&&a===t.toUpperCase()}
/**
 * Create an element, optionally with a known namespace URI.
 *
 * @param {string} name the element name, e.g. 'div' or 'svg'
 * @param {string} [namespaceURI] the element's namespace URI, i.e. the value of
 * its `xmlns` attribute or its inferred namespace.
 *
 * @return {Element}
 */function createElementNS(e,r){return r&&r!==t?a.createElementNS(r,e):a.createElement(e)}function moveChildren(e,r){var t=e.firstChild;while(t){var a=t.nextSibling;r.appendChild(t);t=a}return r}function syncBooleanAttrProp(e,r,t){if(e[t]!==r[t]){e[t]=r[t];e[t]?e.setAttribute(t,""):e.removeAttribute(t)}}var i={OPTION:function(e,r){var t=e.parentNode;if(t){var a=t.nodeName.toUpperCase();if(a==="OPTGROUP"){t=t.parentNode;a=t&&t.nodeName.toUpperCase()}if(a==="SELECT"&&!t.hasAttribute("multiple")){if(e.hasAttribute("selected")&&!r.selected){e.setAttribute("selected","selected");e.removeAttribute("selected")}t.selectedIndex=-1}}syncBooleanAttrProp(e,r,"selected")},INPUT:function(e,r){syncBooleanAttrProp(e,r,"checked");syncBooleanAttrProp(e,r,"disabled");e.value!==r.value&&(e.value=r.value);r.hasAttribute("value")||e.removeAttribute("value")},TEXTAREA:function(e,r){var t=r.value;e.value!==t&&(e.value=t);var a=e.firstChild;if(a){var n=a.nodeValue;if(n==t||!t&&n==e.placeholder)return;a.nodeValue=t}},SELECT:function(e,r){if(!r.hasAttribute("multiple")){var t=-1;var a=0;var n=e.firstChild;var o;var i;while(n){i=n.nodeName&&n.nodeName.toUpperCase();if(i==="OPTGROUP"){o=n;n=o.firstChild}else{if(i==="OPTION"){if(n.hasAttribute("selected")){t=a;break}a++}n=n.nextSibling;if(!n&&o){n=o.nextSibling;o=null}}}e.selectedIndex=t}}};var d=1;var l=11;var u=3;var f=8;function noop(){}function defaultGetNodeKey(e){if(e)return e.getAttribute&&e.getAttribute("id")||e.id}function morphdomFactory(e){return function morphdom(r,t,n){n||(n={});if(typeof t==="string")if(r.nodeName==="#document"||r.nodeName==="HTML"||r.nodeName==="BODY"){var o=t;t=a.createElement("html");t.innerHTML=o}else t=toElement(t);else t.nodeType===l&&(t=t.firstElementChild);var v=n.getNodeKey||defaultGetNodeKey;var m=n.onBeforeNodeAdded||noop;var c=n.onNodeAdded||noop;var s=n.onBeforeElUpdated||noop;var p=n.onElUpdated||noop;var h=n.onBeforeNodeDiscarded||noop;var N=n.onNodeDiscarded||noop;var A=n.onBeforeElChildrenUpdated||noop;var C=n.skipFromChildren||noop;var b=n.addChild||function(e,r){return e.appendChild(r)};var g=n.childrenOnly===true;var T=Object.create(null);var E=[];function addKeyedRemoval(e){E.push(e)}function walkDiscardedChildNodes(e,r){if(e.nodeType===d){var t=e.firstChild;while(t){var a=void 0;if(r&&(a=v(t)))addKeyedRemoval(a);else{N(t);t.firstChild&&walkDiscardedChildNodes(t,r)}t=t.nextSibling}}}
/**
    * Removes a DOM node out of the original DOM
    *
    * @param  {Node} node The node to remove
    * @param  {Node} parentNode The nodes parent
    * @param  {Boolean} skipKeyedNodes If true then elements with keys will be skipped and not discarded.
    * @return {undefined}
    */function removeNode(e,r,t){if(h(e)!==false){r&&r.removeChild(e);N(e);walkDiscardedChildNodes(e,t)}}function indexTree(e){if(e.nodeType===d||e.nodeType===l){var r=e.firstChild;while(r){var t=v(r);t&&(T[t]=r);indexTree(r);r=r.nextSibling}}}indexTree(r);function handleNodeAdded(e){c(e);var r=e.firstChild;while(r){var t=r.nextSibling;var a=v(r);if(a){var n=T[a];if(n&&compareNodeNames(r,n)){r.parentNode.replaceChild(n,r);morphEl(n,r)}else handleNodeAdded(r)}else handleNodeAdded(r);r=t}}function cleanupFromEl(e,r,t){while(r){var a=r.nextSibling;(t=v(r))?addKeyedRemoval(t):removeNode(r,e,true);r=a}}function morphEl(r,t,a){var n=v(t);n&&delete T[n];if(!a){if(s(r,t)===false)return;e(r,t);p(r);if(A(r,t)===false)return}r.nodeName!=="TEXTAREA"?morphChildren(r,t):i.TEXTAREA(r,t)}function morphChildren(e,r){var t=C(e,r);var n=r.firstChild;var o=e.firstChild;var l;var c;var s;var p;var h;e:while(n){p=n.nextSibling;l=v(n);while(!t&&o){s=o.nextSibling;if(n.isSameNode&&n.isSameNode(o)){n=p;o=s;continue e}c=v(o);var N=o.nodeType;var A=void 0;if(N===n.nodeType)if(N===d){if(l){if(l!==c)if(h=T[l])if(s===h)A=false;else{e.insertBefore(h,o);c?addKeyedRemoval(c):removeNode(o,e,true);o=h;c=v(o)}else A=false}else c&&(A=false);A=A!==false&&compareNodeNames(o,n);A&&morphEl(o,n)}else if(N===u||N==f){A=true;o.nodeValue!==n.nodeValue&&(o.nodeValue=n.nodeValue)}if(A){n=p;o=s;continue e}c?addKeyedRemoval(c):removeNode(o,e,true);o=s}if(l&&(h=T[l])&&compareNodeNames(h,n)){t||b(e,h);morphEl(h,n)}else{var g=m(n);if(g!==false){g&&(n=g);n.actualize&&(n=n.actualize(e.ownerDocument||a));b(e,n);handleNodeAdded(n)}}n=p;o=s}cleanupFromEl(e,o,c);var E=i[e.nodeName];E&&E(e,r)}var y=r;var S=y.nodeType;var x=t.nodeType;if(!g)if(S===d)if(x===d){if(!compareNodeNames(r,t)){N(r);y=moveChildren(r,createElementNS(t.nodeName,t.namespaceURI))}}else y=t;else if(S===u||S===f){if(x===S){y.nodeValue!==t.nodeValue&&(y.nodeValue=t.nodeValue);return y}y=t}if(y===t)N(r);else{if(t.isSameNode&&t.isSameNode(y))return;morphEl(y,t,g);if(E)for(var F=0,R=E.length;F<R;F++){var w=T[E[F]];w&&removeNode(w,w.parentNode,false)}}if(!g&&y!==r&&r.parentNode){y.actualize&&(y=y.actualize(r.ownerDocument||a));r.parentNode.replaceChild(y,r)}return y}}var v=morphdomFactory(morphAttrs);export{v as default};

