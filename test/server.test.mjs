import assert from 'node:assert/strict'
import { after, before, test } from 'node:test'
import { createDemoServer } from '../src/server.mjs'

const server = createDemoServer()
let baseUrl

before(async () => {
  await new Promise((resolve) => server.listen(0, '127.0.0.1', resolve))
  const address = server.address()
  baseUrl = `http://127.0.0.1:${address.port}`
})
after(async () => {
  await new Promise((resolve, reject) => server.close((error) => (error ? reject(error) : resolve())))
})

test('serves the demo page', async () => {
  const response = await fetch(baseUrl)
  assert.equal(response.status, 200)
  assert.match(await response.text(), /Local security scan demo/)
})

test('documents the intentionally vulnerable cross-user note response', async () => {
  const response = await fetch(`${baseUrl}/api/notes/2`, { headers: { 'x-user-id': 'alice' } })
  const body = await response.json()
  assert.equal(body.note.ownerId, 'bob')
})
// End of file.
