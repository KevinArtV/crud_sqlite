import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/user_service.dart';

class UserForm extends StatefulWidget {
  const UserForm({super.key, this.user});

  final User? user;

  @override
  State<UserForm> createState() => _UserFormState();
}

class _UserFormState extends State<UserForm> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isSubmitting = false;
  String _error = '';
  bool get _isEditMode => widget.user != null;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      _nameController.text = widget.user!.name!;
      _emailController.text = widget.user!.email!;
    }
  }

  Future<void> _submitForm() async {
    if (_nameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty) {
      setState(() {
        _error = 'Por favor, complete todos los campos.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = '';
    });

    try {
      final user = User(
        id: widget.user?.id ?? 0,
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
      );

      if (_isEditMode) {
        await UserService.updateUser(user);
      } else {
        await UserService.createUser(user);
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Modificar un usuario' : 'Crear un usuario'),
      ), //AppBar
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Nombre'),
              textInputAction: TextInputAction.next,
            ),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Correo electrónico'),
              textInputAction: TextInputAction.done,
            ),
            if (_error.isNotEmpty)
              Text(_error, style: TextStyle(color: Colors.red)),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submitForm,
              child: _isSubmitting
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_isEditMode ? 'Actualizar' : 'Crear'),
            ),
          ],
        ),
      ),
    );
  }
}
