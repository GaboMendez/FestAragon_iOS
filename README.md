# ¡Viva mi pueblo en fiestas!

## Descripción

Nuestra aplicación deberá publicar información de un pueblo de Aragón en fiestas. Durante nuestras fiestas, los pueblos organizan distintos tipos de eventos de muy diversas categorías. Estos pueden ser: conciertos, espectáculos musicales y culturales, ferias y atracciones para niños, torneos de cartas, mercados o eventos tradicionales.

Los usuarios deben poder navegar durante los días festivos de forma directa, mostrando los eventos de cada uno de los días. Queremos además proponer búsquedas rápidas por las categorías principales o búsquedas textuales. Todas las búsquedas podrán ir filtradas de forma por proximidad futura. Es decir, el usuario decidirá si quiere ver o no eventos pasados.

Cualquier evento o actividad, deberá tener: título, fecha, lugar, imagen o recurso multimedia, descripción del evento y organizador. Toda esta información será visible desde la pantalla de detalle, donde mostraremos la ubicación donde va a tener lugar (habrá que geolocalizarlos), y de forma recomendada la posibilidad de obtener la ruta a dicho lugar desde donde nos encontremos.

Para poder disfrutar de las fiestas, podremos marcar eventos como favoritos, creando nuestra propia agenda que, idealmente, deberá notificarnos con alertas o avisos 15 minutos antes de que tenga lugar el evento.

Se espera un diseño, tanto gráfico como de patrones de interacción, estandarizado. No será necesario incluir peticiones de red ya que todos los eventos irán definidos en un único archivo JSON.

Además, también podremos compartir eventos por email compartiendo un texto fijo y pudiendo añadir un archivo multimedia.

## Presupuesto

El presupuesto disponible es de 120 horas, ya que el grupo está compuesto por 4 integrantes y cada uno debe dedicarle 30h al proyecto.

## Objetivo

Entregar una aplicación completamente funcional que presente los eventos más relevantes de las festividades de un pueblo de la comunidad autónoma de Aragón.

## Requisitos

- Navegación por fecha.
- Navegación por categoría.
- Filtrado por valor más cercano.
- Filtrado por categoría.
- Manejo de funcionalidades del dispositivo.
- Gestión de permisos.
- Gestión de tareas.
- Mapas y herramientas de GoogleMaps.
- Gestión de estado y ciclo de vida.
- Estilo unificado: interacciones, diseño y codificación.

## Guía para Desarrolladores

Para mantener un flujo de trabajo organizado y colaborativo, seguiremos una metodología de desarrollo basada en features. Cada requisito del proyecto será tratado como una feature individual.

### Ramas de Features (Feature Branches)

Cada vez que comiences a trabajar en un nuevo requisito, deberás crear una nueva rama (branch) a partir de la rama `develop`. El nombre de la rama debe seguir la siguiente convención:

`feature/<nombre-del-requisito>`

Por ejemplo, si estás trabajando en el requisito "Navegación por fecha", el nombre de tu rama sería:

`feature/navegacion-por-fecha`

**Flujo de trabajo:**

1.  Asegúrate de que tu rama `develop` local esté actualizada: `git checkout develop && git pull origin develop`
2.  Crea tu rama de feature: `git checkout -b feature/<nombre-del-requisito>`
3.  Realiza los commits necesarios en tu rama de feature.
4.  Una vez que hayas completado el desarrollo de la feature, sube tu rama al repositorio remoto: `git push origin feature/<nombre-del-requisito>`
5.  Crea un Pull Request (PR) en GitHub/GitLab para fusionar tu rama de feature en `develop`.
6.  Asigna revisores a tu PR para que revisen el código.
7.  Una vez que el PR sea aprobado y las pruebas pasen, se podrá fusionar a `develop`.

Este enfoque nos permitirá trabajar en paralelo en diferentes funcionalidades, mantener el código de la rama principal estable y facilitar la revisión de código.

## TRELLO
https://trello.com/invite/b/6967b73bf1e99a8647f839c3/ATTIbe24d7173321ea67fc7ec88e7b7e4e5a623C257E/trabajo-grupal-ios