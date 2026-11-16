// v0.21.2: roda a parte de fundo (fundo/fundo.js) com um navegador de mentira e confere que a ponte entra na
// página do Compras IFTO. Pegou o erro da v0.19.0 a v0.21.1 ("compras is not defined": a ponte nunca entrava).
const { test } = require('node:test')
const assert = require('node:assert/strict')
const fs = require('node:fs')
const path = require('node:path')
const vm = require('node:vm')

function navegadorDeMentira () {
  const ouvintes = {}
  const evento = nome => ({ addListener: f => { (ouvintes[nome] = ouvintes[nome] || []).push(f) } })
  const injetados = []
  const guardado = {}
  const api = {
    runtime: { onInstalled: evento('instalado'), onStartup: evento('inicio'), onMessage: evento('recado'), getURL: c => 'ext://' + c },
    contextMenus: { removeAll: f => f && f(), create: () => {}, onClicked: evento('menu') },
    storage: { local: { get: async chave => ({ [chave]: guardado[chave] }), set: async dados => Object.assign(guardado, dados), remove: async () => {} } },
    tabs: { onUpdated: evento('aba'), query: async () => [], sendMessage: async () => ({}), update: async () => ({}), create: async () => ({}) },
    scripting: { executeScript: async pedido => { injetados.push(pedido); return [{ result: null }] } },
    permissions: { onAdded: evento('permissao'), contains: async () => true },
    windows: { create: async () => ({ id: 1, tabs: [{ id: 2 }] }), remove: async () => {}, update: async () => {} },
    downloads: {}
  }
  return { api, ouvintes, injetados, guardado }
}

function carregarFundo () {
  const falso = navegadorDeMentira()
  const contexto = vm.createContext({ console, setTimeout, clearTimeout, URL, TextDecoder, TextEncoder, chrome: falso.api })
  contexto.globalThis = contexto
  const raiz = path.join(__dirname, '..')
  const manifest = JSON.parse(fs.readFileSync(path.join(raiz, 'manifest.json'), 'utf8'))
  // Mesma ordem do manifest (Firefox); pdf-texto.js fica de fora (precisa do pdf.js).
  for (const arquivo of manifest.background.scripts.filter(a => !a.endsWith('pdf-texto.js'))) {
    vm.runInContext(fs.readFileSync(path.join(raiz, arquivo), 'utf8'), contexto, { filename: arquivo })
  }
  return falso
}

test('fundo: carrega sem erro com todos os scripts do manifest', () => {
  assert.doesNotThrow(carregarFundo)
})

test('fundo: página do Compras IFTO carregada recebe a ponte; outras páginas não', async () => {
  const { ouvintes, injetados } = carregarFundo()
  for (const ouvir of ouvintes.aba) await ouvir(7, { status: 'complete' }, { url: 'https://compras-ifto-teste-v1-mbro.onrender.com/#/processo/p1/dfd' })
  for (const ouvir of ouvintes.aba) await ouvir(8, { status: 'complete' }, { url: 'https://exemplo.com/' })
  await new Promise(r => setTimeout(r, 0))
  const ponte = injetados.filter(pedido => (pedido.files || []).includes('sites/compras-ifto/ponte.js'))
  assert.equal(ponte.length, 1)
  assert.equal(ponte[0].target.tabId, 7)
  assert.equal(JSON.stringify(ponte[0].files), JSON.stringify(['comum/compras-ifto.js', 'sites/compras-ifto/ponte.js']))
})

test('fundo: peça do Compras IFTO entra na lista; de outro site é recusada', async () => {
  const { ouvintes, guardado } = carregarFundo()
  const mandar = (recado, remetente) => new Promise(resolve => { const r = ouvintes.recado[0](recado, remetente, resolve); if (r !== true) resolve(undefined) })
  const peca = { id: 'p1:dfd', titulo: 'DOCUMENTO DE FORMALIZAÇÃO DA DEMANDA', html: '<p>Texto</p>' }
  assert.equal(JSON.stringify(await mandar({ tipo: 'comprasPeca', peca }, { url: 'https://compras-ifto-teste-v1-mbro.onrender.com/#/processo/p1/dfd' })), JSON.stringify({ ok: true, total: 1 }))
  assert.equal(guardado.pecasCompras[0].id, 'p1:dfd')
  assert.ok((await mandar({ tipo: 'comprasPeca', peca }, { url: 'https://outro.site/' })).erro)
})
