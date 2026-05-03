/// Devuelve el emoji que representa un cultivo a partir de su nombre común.
/// Si el nombre no está mapeado, devuelve 🌱 como fallback.
String iconoCultivo(String? nombre) {
  switch (nombre?.toLowerCase()) {
    // Granos y cereales
    case 'café arábica':
    case 'café robusta':
      return '☕';
    case 'maíz':
      return '🌽';
    case 'arroz':
    case 'quinua':
      return '🌾';
    case 'frijol':
      return '🫘';

    // Frutas
    case 'plátano':
    case 'banano':
      return '🍌';
    case 'aguacate':
      return '🥑';
    case 'naranja':
    case 'mandarina':
      return '🍊';
    case 'limón':
      return '🍋';
    case 'mango':
      return '🥭';
    case 'papaya':
      return '🫒';
    case 'piña':
      return '🍍';
    case 'maracuyá':
    case 'granadilla':
      return '🥝';
    case 'lulo':
    case 'tomate de árbol':
    case 'tomate':
      return '🍅';
    case 'mora de castilla':
      return '🫐';
    case 'fresa':
      return '🍓';
    case 'uchuva':
      return '🍒';
    case 'guayaba':
      return '🍐';
    case 'chontaduro':
      return '🥥';

    // Hortalizas
    case 'lechuga':
      return '🥬';
    case 'cebolla cabezona':
    case 'cebolla larga':
      return '🧅';
    case 'cilantro':
      return '🌿';
    case 'zanahoria':
      return '🥕';

    // Tubérculos
    case 'papa':
    case 'yuca':
      return '🥔';

    // Industriales
    case 'cacao':
      return '🍫';
    case 'caña de azúcar':
    case 'caña panelera':
      return '🎋';
    case 'palma de aceite':
      return '🌴';

    default:
      return '🌱';
  }
}

/// Devuelve el emoji que representa el tipo de un proyecto.
String iconoProyecto(String tipo) {
  switch (tipo.toLowerCase()) {
    case 'invernadero':
      return '🏠';
    case 'huerto':
      return '🌿';
    case 'parcela':
      return '🟫';
    case 'vivero':
      return '🌱';
    case 'jardín urbano':
      return '🏙️';
    case 'terraza':
      return '🏗️';
    default:
      return '🌾';
  }
}
