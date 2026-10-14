import { createServer } from 'node:http'

const notes = new Map([
  ['1', { id: '1', ownerId: 'alice', body: 'Alice demo note' }],
  ['2', { id: '2', ownerId: 'bob', body: 'Bob demo note' }],
])

export function createDemoServer() {
  return createServer((request, response) => {
    const url = new URL(request.url ?? '/', 'http://localhost')

    if (url.pathname === '/') {
      response.setHeader('content-type', 'text/html; charset=utf-8')
      response.end(`<!doctype html>
<html lang="en">
  <head><meta charset="utf-8"><title>Shannon Daybreak Blue demo</title></head>
  <body>
    <h1>Local security scan demo</h1>
    <form action="/search"><input name="q"><button>Search</button></form>
    <p>Demo users: alice and bob. Send the user in the x-user-id header.</p>
  </body>
</html>`)
      return
    }

    if (url.pathname === '/search') {
      const query = url.searchParams.get('q') ?? ''
      response.setHeader('content-type', 'text/html; charset=utf-8')
      // Intentionally vulnerable: reflected input is written into HTML unchanged.
      response.end(`<h1>Search results for ${query}</h1>`)
      return
    }

    const noteMatch = url.pathname.match(/^\/api\/notes\/(\d+)$/)
    if (noteMatch) {
      const note = notes.get(noteMatch[1])
      if (!note) {
        response.writeHead(404).end('Not found')
        return
      }

      // Intentionally vulnerable: the caller identity is read but ownership is not checked.
      const currentUserId = request.headers['x-user-id']
      response.setHeader('content-type', 'application/json')
      response.end(JSON.stringify({ currentUserId, note }))
      return
    }

    response.writeHead(404).end('Not found')
  })
}
if (process.argv[1] === new URL(import.meta.url).pathname) {
  const host = process.env.HOST ?? '127.0.0.1'
  const port = Number(process.env.PORT ?? 4173)
  createDemoServer().listen(port, host, () => {
    console.log(`Demo listening on http://${host}:${port}`)
  })
}
// End of file.
