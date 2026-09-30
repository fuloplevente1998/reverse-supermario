# 0.1.7 – az első pálya oldalnézeti változata

A 2026-09-30-i két felhasználói mockup alapján most csak az első pálya készül tovább. A további kilenc pálya nem kapott új útvonalat. Az első pálya alapértelmezett nézete oldalnézet; a nézetváltás elérhető, de a 3D-s díszlet további kidolgozása későbbi feladat.

- A bejárható szakasz -15 és 225 méter között van: 240 méter, a korábbi 60 méter négyszerese.
- Két emelkedő-gerinc, lejtők, mélyebb völgy, négy valódi rés, egy vizes árok és egy rövid lépcsős szakasz.
- Ellenőrzőpontok: 44, 104 és 168 méter. A visszatérés megőrzi a terep helyi magasságát.
- Az ortografikus kamera a talajt a kép alsó negyedéhez igazítja, előretekint és követi a terep magasságát. A hétköznapi ugrás nem mozgatja fel-le a kamerát.
- Rajzolási rétegek: 1 = játéktér és szereplők; 2 = a korábbi 3D-s díszlet; 4 = az első pálya oldalnézeti panorámája és célzászlója.
- Az ugrás 0,10 másodperces lelépési türelmet és 0,12 másodperces bemeneti puffert kapott az első pálya oldalnézetében.

## Háttérkép

Fájl: `assets/backgrounds/courtyard_side_panorama.jpg`.
A beépített imagegen eszközzel készült, majd JPEG formátumban került a projektbe. Statikus, kezelőfelület és szereplők nélküli kép; a járható terep valódi ütközőgeometria előtte. A szomszédos panelek tükrözése illeszti a képszéleket.

Végső prompt: Production game asset, a wide horizontally tileable matte-painting background for a side-scrolling medieval castle courtyard game, 3:1. Warm cream limestone ramparts and round castle towers, blue slate conical roofs, red and gold banners, cypress trees, ivy, flowers, distant hazy green hills and a fairy-tale castle, clear blue sky with soft clouds. Polished stylized 3D illustration with warm sunlight. Strict side elevation, slightly muted background architecture. Lower quarter distant garden retaining walls and shaded foliage. No people, characters, weapons, interface, buttons, text, foreground objects, playable ground platform or road pointing into depth. One continuous panorama.

## Ellenőrzés

`tests/first_course_smoke.gd`: teljes végigjátszás a rendes játékosfizikával, lejtők és rések, kamera vetülete, ütközésmagasságok, ellenőrzőpontok, tényleges vízbe érkezés és visszatérés.
`tests/side_course_preview.gd`: hét pályapont és széles telefonképarány képi ellenőrzése.
A meglévő karakter-, oldalnézet-, környezet- és 30 pálya/nehézség-kombinációs teszt továbbra is fut.

A mockup művészeti referencia; az APK tényleges látványa a buildben mentett játékfotókon ellenőrizhető. Telefonos teljesítmény- és kényelmi próba még szükséges.
