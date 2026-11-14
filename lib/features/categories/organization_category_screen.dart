import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/providers/queue_providers.dart';

class OrganizationCategoryScreen extends ConsumerStatefulWidget {
  const OrganizationCategoryScreen({super.key});

  @override
  ConsumerState<OrganizationCategoryScreen> createState() => _OrganizationCategoryScreenState();
}

class _OrganizationCategoryScreenState extends ConsumerState<OrganizationCategoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _customSubCatController = TextEditingController();

  OrganizationCategory _selectedCategory = OrganizationCategoryManager.healthcare;
  OrganizationSubCategory? _selectedSubCategory;
  String _searchQuery = '';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final biz = ref.read(currentBusinessProvider);
    if (biz != null) {
      _selectedCategory = OrganizationCategoryManager.findCategory(biz.category);
      _selectedSubCategory = OrganizationCategoryManager.findSubCategory(biz.category, biz.subCategory);
    }
    _selectedSubCategory ??= _selectedCategory.subCategories.firstOrNull;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _customSubCatController.dispose();
    super.dispose();
  }

  Future<void> _applyCategory({bool provisionServices = false}) async {
    final bizId = ref.read(selectedBusinessIdProvider);
    final branchId = ref.read(selectedBranchIdProvider);
    if (bizId.isEmpty) return;

    setState(() => _isSaving = true);

    try {
      final subCatName = _selectedSubCategory?.name ?? '';

      // 1. Update business document
      await FirebaseFirestore.instance.collection('businesses').doc(bizId).update({
        'category': _selectedCategory.id,
        'subCategory': subCatName,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 2. Optionally auto-provision starter services for this subcategory
      if (provisionServices && branchId.isNotEmpty && _selectedSubCategory != null) {
        final templates = _selectedSubCategory!.defaultServices.isNotEmpty
            ? _selectedSubCategory!.defaultServices
            : _selectedCategory.defaultServices;

        if (templates.isNotEmpty) {
          final batch = FirebaseFirestore.instance.batch();

          for (int i = 0; i < templates.length; i++) {
            final tpl = templates[i];
            final sId = 'service_${DateTime.now().millisecondsSinceEpoch}_$i';

            final sRef = FirebaseFirestore.instance
                .collection('businesses')
                .doc(bizId)
                .collection('branches')
                .doc(branchId)
                .collection('services')
                .doc(sId);

            batch.set(sRef, {
              'id': sId,
              'businessId': bizId,
              'branchId': branchId,
              'name': tpl.name,
              'code': tpl.code,
              'estimatedDurationMinutes': tpl.durationMinutes,
              'description': tpl.description,
              'maxQueueCapacity': tpl.maxCapacity,
              'allowWalkIn': tpl.allowWalkIn,
              'supportsPriority': tpl.supportsPriority,
              'allocationPolicy': tpl.allocationPolicy,
              'status': 'ACTIVE',
              'isActive': true,
              'createdAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            });

            final qRef = FirebaseFirestore.instance
                .collection('businesses')
                .doc(bizId)
                .collection('branches')
                .doc(branchId)
                .collection('queues')
                .doc(sId);

            batch.set(qRef, {
              'id': sId,
              'businessId': bizId,
              'branchId': branchId,
              'serviceId': sId,
              'tokenPrefix': tpl.code,
              'tokenSequenceDate': DateTime.now().toIso8601String().substring(0, 10),
              'lastTokenNumber': 0,
              'waitingCount': 0,
              'calledCount': 0,
              'servingCount': 0,
              'completedCount': 0,
              'status': 'OPEN',
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }

          await batch.commit();
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provisionServices
                ? 'Category updated & starter queues provisioned for ${_selectedSubCategory?.name}!'
                : 'Category updated to ${_selectedCategory.name} • $subCatName!'),
            backgroundColor: Colors.green.shade700,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update category: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showAddCustomSubCategoryDialog() {
    _customSubCatController.clear();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Custom Type for ${_selectedCategory.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter your specialized organization type or custom business classification:',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _customSubCatController,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Organization Type',
                hintText: 'e.g. Pet Grooming Lounge, Drone Academy',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final customName = _customSubCatController.text.trim();
              if (customName.isEmpty) return;
              Navigator.pop(ctx);

              final newSub = OrganizationSubCategory.fromCustomName(customName);
              setState(() {
                _selectedSubCategory = newSub;
              });
            },
            child: const Text('Add Custom Type'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final searchResults = _searchQuery.isNotEmpty ? OrganizationCategoryManager.search(_searchQuery) : <OrganizationSubCategory>[];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Organization Category Management'),
      ),
      body: Column(
        children: [
          // 1. Search Box
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search 100+ categories (e.g. dental, rto, tattoo, darshan)...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
            ),
          ),

          // 2. Active Selection Badge Banner
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: Row(
              children: [
                Icon(_selectedCategory.icon, color: _selectedCategory.brandColor, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Category ${_selectedCategory.code}: ${_selectedCategory.name}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E3A8A)),
                      ),
                      Text(
                        'Selected: ${_selectedSubCategory?.name ?? "None"}',
                        style: TextStyle(fontSize: 12, color: Colors.blue.shade900),
                      ),
                    ],
                  ),
                ),
                if (_selectedSubCategory?.isCustom == true)
                  Chip(
                    label: const Text('CUSTOM', style: TextStyle(fontSize: 10, color: Colors.purple, fontWeight: FontWeight.bold)),
                    backgroundColor: Colors.purple.shade50,
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
          ),

          // 3. Main Content: Search Mode or Category Browser
          Expanded(
            child: _searchQuery.isNotEmpty
                ? _buildSearchResultsList(searchResults)
                : _buildCategoryBrowser(),
          ),

          // 4. Bottom Action Bar
          _buildBottomActionBar(),
        ],
      ),
    );
  }

  Widget _buildSearchResultsList(List<OrganizationSubCategory> results) {
    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_outlined, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text('No categories matching "$_searchQuery"', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextButton.icon(
              icon: const Icon(Icons.add),
              label: Text('Create custom "$_searchQuery" type'),
              onPressed: () {
                final newSub = OrganizationSubCategory.fromCustomName(_searchQuery);
                setState(() {
                  _selectedSubCategory = newSub;
                  _searchController.clear();
                  _searchQuery = '';
                });
              },
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: results.length,
      itemBuilder: (context, idx) {
        final sub = results[idx];
        final isSelected = _selectedSubCategory?.id == sub.id;

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: isSelected ? const Color(0xFF2563EB) : Colors.grey.shade200, width: isSelected ? 2 : 1),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isSelected ? const Color(0xFF2563EB) : Colors.blue.shade50,
              child: Icon(sub.icon, size: 20, color: isSelected ? Colors.white : const Color(0xFF2563EB)),
            ),
            title: Text(sub.name, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.w600)),
            subtitle: Text(sub.description, style: const TextStyle(fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
            trailing: isSelected ? const Icon(Icons.check_circle, color: Color(0xFF2563EB)) : null,
            onTap: () {
              // Locate parent category
              for (final cat in OrganizationCategoryManager.defaultCategories) {
                if (cat.subCategories.any((s) => s.id == sub.id)) {
                  _selectedCategory = cat;
                  break;
                }
              }
              setState(() {
                _selectedSubCategory = sub;
                _searchController.clear();
                _searchQuery = '';
              });
            },
          ),
        );
      },
    );
  }

  Widget _buildCategoryBrowser() {
    return Row(
      children: [
        // Left Column: 15 Master Categories (A through O)
        SizedBox(
          width: 130,
          child: ListView.builder(
            itemCount: OrganizationCategoryManager.defaultCategories.length,
            itemBuilder: (context, index) {
              final cat = OrganizationCategoryManager.defaultCategories[index];
              final isSelected = _selectedCategory.id == cat.id;

              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedCategory = cat;
                    _selectedSubCategory = cat.subCategories.firstOrNull;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white : Colors.grey.shade50,
                    border: Border(
                      left: BorderSide(
                        color: isSelected ? cat.brandColor : Colors.transparent,
                        width: 4,
                      ),
                      bottom: BorderSide(color: Colors.grey.shade200, width: 0.5),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: cat.brandColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              cat.code,
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: cat.brandColor),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(cat.icon, size: 16, color: cat.brandColor),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        cat.name,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? Colors.black87 : Colors.grey.shade700,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${cat.subCategories.length} types',
                        style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        const VerticalDivider(width: 1),

        // Right Column: Sub-Categories of the selected Category
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '${_selectedCategory.code}. ${_selectedCategory.name}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                  TextButton.icon(
                    style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Custom', style: TextStyle(fontSize: 12)),
                    onPressed: _showAddCustomSubCategoryDialog,
                  ),
                ],
              ),
              const SizedBox(height: 8),

              ..._selectedCategory.subCategories.map((sub) {
                final isSelected = _selectedSubCategory?.id == sub.id;

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(
                      color: isSelected ? _selectedCategory.brandColor : Colors.grey.shade200,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                    leading: Icon(sub.icon, size: 20, color: isSelected ? _selectedCategory.brandColor : Colors.grey.shade600),
                    title: Text(
                      sub.name,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                        fontSize: 13,
                        color: isSelected ? _selectedCategory.brandColor : Colors.black87,
                      ),
                    ),
                    subtitle: Text(
                      sub.description,
                      style: const TextStyle(fontSize: 11),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: isSelected
                        ? Icon(Icons.check_circle, color: _selectedCategory.brandColor, size: 20)
                        : null,
                    onTap: () {
                      setState(() => _selectedSubCategory = sub);
                    },
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomActionBar() {
    final templates = _selectedSubCategory?.defaultServices ?? _selectedCategory.defaultServices;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), offset: const Offset(0, -3), blurRadius: 8),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (templates.isNotEmpty) ...[
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  const Text('Tailored queues: ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                  ...templates.take(3).map((t) => Chip(
                        label: Text('${t.code} - ${t.name}', style: const TextStyle(fontSize: 10)),
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                      )),
                  if (templates.length > 3)
                    Text('+${templates.length - 3} more', style: const TextStyle(fontSize: 10, color: Colors.blue)),
                ],
              ),
              const SizedBox(height: 8),
            ],
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSaving ? null : () => _applyCategory(provisionServices: false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Save to Profile'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    icon: _isSaving
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.auto_awesome, size: 18),
                    label: const Text('Apply & Auto-Provision Queues'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _isSaving ? null : () => _applyCategory(provisionServices: true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
