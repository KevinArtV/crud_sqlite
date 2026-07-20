import 'package:flutter/material.dart';
import '../models/contact.dart';
import '../services/contact_service.dart';
import 'contact_form.dart';

class ContactListPage extends StatefulWidget {
  const ContactListPage({super.key});

  @override
  State<ContactListPage> createState() => _ContactListPageState();
}

class _ContactListPageState extends State<ContactListPage> {
  List<Contact> _allContacts = [];
  List<Contact> _filteredContacts = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final _searchController = TextEditingController();
  int _selectedFilterIndex = 0; // 0 = Todos, 1 = Favoritos

  // Genera un color consistente basado en el nombre del contacto
  Color _getAvatarColor(String name) {
    if (name.isEmpty) return Colors.grey;
    final int hash = name.codeUnits.fold(0, (prev, elem) => prev + elem);
    final List<Color> colors = [
      Colors.deepPurple,
      Colors.indigo,
      Colors.blue,
      Colors.teal,
      Colors.green,
      Colors.orange,
      Colors.pink,
      Colors.red,
    ];
    return colors[hash % colors.length];
  }

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadContacts() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final contacts = await ContactService.getContacts();
      if (mounted) {
        setState(() {
          _allContacts = contacts;
          _applyFiltersAndSearch();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar contactos: $e')),
        );
      }
    }
  }

  void _applyFiltersAndSearch() {
    List<Contact> temp = List.from(_allContacts);

    // Filtrar por favoritos si corresponde
    if (_selectedFilterIndex == 1) {
      temp = temp.where((c) => c.isFavorite).toList();
    }

    // Filtrar por consulta de búsqueda
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      temp = temp.where((c) {
        final name = (c.name ?? '').toLowerCase();
        final phone = (c.phone ?? '').toLowerCase();
        final email = (c.email ?? '').toLowerCase();
        return name.contains(query) || phone.contains(query) || email.contains(query);
      }).toList();
    }

    setState(() {
      _filteredContacts = temp;
    });
  }

  Future<void> _toggleFavorite(Contact contact) async {
    try {
      await ContactService.toggleFavorite(contact);
      // Actualizar localmente para una respuesta de UI instantánea y suave
      setState(() {
        contact.isFavorite = !contact.isFavorite;
        // Si estamos en la pestaña de favoritos, podríamos tener que quitarlo de la vista
        _applyFiltersAndSearch();
      });
      // Recargar todos para asegurar que el orden de favoritos es correcto
      final updatedList = await ContactService.getContacts();
      if (mounted) {
        setState(() {
          _allContacts = updatedList;
          _applyFiltersAndSearch();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al actualizar favorito: $e')),
        );
      }
    }
  }

  Future<void> _confirmDelete(Contact contact) async {
    final theme = Theme.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
            const SizedBox(width: 8),
            const Text('Eliminar contacto'),
          ],
        ),
        content: Text('¿Está seguro de que desea eliminar a "${contact.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true && contact.id != null) {
      try {
        await ContactService.deleteContact(contact.id!);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text('Contacto eliminado correctamente'),
          ),
        );
        _loadContacts();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al eliminar contacto: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final favoritesCount = _allContacts.where((c) => c.isFavorite).length;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header Section
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Agenda',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      Text(
                        '${_allContacts.length} contactos en total',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 18),
                        const SizedBox(width: 4),
                        Text(
                          '$favoritesCount Favoritos',
                          style: TextStyle(
                            color: Colors.orange.shade800,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Buscar por nombre, teléfono o email...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                              _applyFiltersAndSearch();
                            });
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                    _applyFiltersAndSearch();
                  });
                },
              ),
            ),

            // Segmented Filter Controls
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildFilterTab(0, 'Todos', Icons.people),
                    ),
                    Expanded(
                      child: _buildFilterTab(1, 'Favoritos', Icons.star),
                    ),
                  ],
                ),
              ),
            ),

            // Contact List View
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredContacts.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          onRefresh: _loadContacts,
                          child: ListView.builder(
                            itemCount: _filteredContacts.length,
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemBuilder: (context, index) {
                              final contact = _filteredContacts[index];
                              final avatarColor = _getAvatarColor(contact.name ?? '');
                              
                              return Card(
                                elevation: 0.5,
                                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  side: BorderSide(
                                    color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: ListTile(
                                    leading: Hero(
                                      tag: 'avatar_${contact.id}',
                                      child: CircleAvatar(
                                        radius: 24,
                                        backgroundColor: avatarColor.withValues(alpha: 0.2),
                                        child: Text(
                                          contact.name?.isNotEmpty == true
                                              ? contact.name![0].toUpperCase()
                                              : '?',
                                          style: TextStyle(
                                            color: avatarColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                          ),
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      contact.name ?? '',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(Icons.phone, size: 14, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7)),
                                            const SizedBox(width: 6),
                                            Text(contact.phone ?? ''),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            Icon(Icons.email, size: 14, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7)),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                contact.email ?? '',
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Quick Star Toggle
                                        IconButton(
                                          icon: Icon(
                                            contact.isFavorite ? Icons.star : Icons.star_border,
                                            color: contact.isFavorite ? Colors.amber : Colors.grey.shade400,
                                          ),
                                          onPressed: () => _toggleFavorite(contact),
                                          tooltip: contact.isFavorite ? 'Quitar de favoritos' : 'Agregar a favoritos',
                                        ),
                                        // Actions Menu
                                        PopupMenuButton<String>(
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          icon: Icon(Icons.more_vert, color: theme.colorScheme.onSurfaceVariant),
                                          onSelected: (value) async {
                                            if (value == 'edit') {
                                              final updated = await Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => ContactForm(contact: contact),
                                                ),
                                              );
                                              if (updated == true) {
                                                _loadContacts();
                                              }
                                            } else if (value == 'delete') {
                                              _confirmDelete(contact);
                                            }
                                          },
                                          itemBuilder: (context) => [
                                            PopupMenuItem(
                                              value: 'edit',
                                              child: Row(
                                                children: [
                                                  Icon(Icons.edit, color: theme.colorScheme.primary, size: 20),
                                                  const SizedBox(width: 8),
                                                  const Text('Editar'),
                                                ],
                                              ),
                                            ),
                                            PopupMenuItem(
                                              value: 'delete',
                                              child: Row(
                                                children: [
                                                  const Icon(Icons.delete, color: Colors.red, size: 20),
                                                  const SizedBox(width: 8),
                                                  const Text('Eliminar'),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ContactForm(),
            ),
          );
          if (created == true) {
            _loadContacts();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Agregar'),
        elevation: 4,
      ),
    );
  }

  Widget _buildFilterTab(int index, String text, IconData icon) {
    final theme = Theme.of(context);
    final isSelected = _selectedFilterIndex == index;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilterIndex = index;
          _applyFiltersAndSearch();
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              text,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    final isSearchActive = _searchQuery.isNotEmpty;
    
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isSearchActive 
                      ? Icons.search_off_rounded 
                      : (_selectedFilterIndex == 1 ? Icons.star_border_rounded : Icons.people_outline_rounded),
                  size: 64,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                isSearchActive
                    ? 'No se encontraron resultados'
                    : (_selectedFilterIndex == 1 ? 'No hay favoritos' : 'Tu agenda está vacía'),
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                isSearchActive
                    ? 'Prueba a buscar con otros términos o limpia el campo de búsqueda'
                    : (_selectedFilterIndex == 1
                        ? 'Marca tus contactos importantes con una estrella para verlos aquí'
                        : 'Comienza a agregar contactos presionando el botón de abajo'),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              if (isSearchActive) ...[
                const SizedBox(height: 24),
                TextButton.icon(
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                      _applyFiltersAndSearch();
                    });
                  },
                  icon: const Icon(Icons.clear),
                  label: const Text('Limpiar búsqueda'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
