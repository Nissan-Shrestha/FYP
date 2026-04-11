import 'package:fit_app/constants.dart';
import 'package:fit_app/models/clothing_item_model.dart';
import 'package:fit_app/screens/wardrobe/clothing_item_detail_screen.dart';
import 'package:fit_app/screens/wardrobe/edit_clothing_item_screen.dart';
import 'package:fit_app/viewmodels/auth_viewmodel.dart';
import 'package:fit_app/viewmodels/wardrobe_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class WardrobeViewScreen extends StatefulWidget {
  final int wardrobeId;
  final String wardrobeName;
  final bool isDefaultWardrobe;
  final bool readOnly;

  const WardrobeViewScreen({
    super.key,
    required this.wardrobeId,
    required this.wardrobeName,
    this.isDefaultWardrobe = false,
    this.readOnly = false,
  });

  @override
  State<WardrobeViewScreen> createState() => _WardrobeViewScreenState();
}

class _WardrobeViewScreenState extends State<WardrobeViewScreen> {
  String _selectedSort = "Recently Added";
  bool _requestedLoad = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_requestedLoad) return;

    final firebaseUid = context.read<AuthViewmodel>().profile?.firebaseUid;
    if (firebaseUid == null) return;

    _requestedLoad = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final wardrobeVM = context.read<WardrobeViewmodel>();
      wardrobeVM.fetchItemsForWardrobe(wardrobeId: widget.wardrobeId);
      if (wardrobeVM.clothingItems.isEmpty) {
        wardrobeVM.fetchClothingItems();
      }
    });
  }

  Future<void> _showAddItemsSheet() async {
    final authVM = context.read<AuthViewmodel>();
    final wardrobeVM = context.read<WardrobeViewmodel>();
    final firebaseUid = authVM.profile?.firebaseUid;

    if (firebaseUid == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("User not found")));
      return;
    }

    if (wardrobeVM.clothingItems.isEmpty &&
        !wardrobeVM.isLoadingClothingItems) {
      await wardrobeVM.fetchClothingItems();
    }

    if (!mounted) return;

    final selectedIds = wardrobeVM.selectedWardrobeItems
        .map((e) => e.id)
        .toSet();

    final selectedToAdd = <int>{};

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (modalContext, setSheetState) {
            final vm = modalContext.watch<WardrobeViewmodel>();
            final allItems = vm.clothingItems;
            final availableItems = allItems
                .where((item) => !selectedIds.contains(item.id))
                .toList();

            return SafeArea(
              child: SizedBox(
                height: MediaQuery.of(sheetContext).size.height * 0.7,
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Add Items to ${capitalize(widget.wardrobeName)}",
                      style: GoogleFonts.manrope(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (availableItems.isNotEmpty)
                      Text(
                        "${selectedToAdd.length} selected",
                        style: const TextStyle(
                          fontSize: 10.8,
                          color: Colors.black54,
                        ),
                      ),
                    const SizedBox(height: 10),
                    if (vm.isLoadingClothingItems)
                      const Expanded(
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (availableItems.isEmpty)
                      Expanded(
                        child: Center(
                          child: Text(
                            "No more items available to add",
                            style: GoogleFonts.manrope(fontSize: 16.2),
                          ),
                        ),
                      )
                    else
                      Expanded(
                        child: ListView.separated(
                          itemCount: availableItems.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final item = availableItems[index];
                            final imageUrl = item.image == null
                                ? null
                                : item.image!.startsWith("http")
                                ? item.image!
                                : "${ApiConfig.serverBaseUrl}${item.image!}";
                            final isSelected = selectedToAdd.contains(item.id);

                            return ListTile(
                              onTap: () {
                                setSheetState(() {
                                  if (isSelected) {
                                    selectedToAdd.remove(item.id);
                                  } else {
                                    selectedToAdd.add(item.id);
                                  }
                                });
                              },
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  width: 44,
                                  height: 44,
                                  color: Colors.grey.shade300,
                                  child: imageUrl == null
                                      ? const Icon(
                                          Icons.checkroom_outlined,
                                          size: 20,
                                        )
                                      : Image.network(
                                          imageUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              const Icon(
                                                Icons.broken_image_outlined,
                                              ),
                                        ),
                                ),
                              ),
                              title: Text(
                                capitalize(item.name),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                [
                                  item.category,
                                  item.occasion,
                                ].where((e) => e.trim().isNotEmpty).join(" | "),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: Icon(
                                isSelected
                                    ? Icons.check_circle
                                    : Icons.radio_button_unchecked,
                                color: isSelected ? Colors.green : Colors.grey,
                              ),
                            );
                          },
                        ),
                      ),
                    if (availableItems.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: selectedToAdd.isEmpty || vm.isSubmitting
                                ? null
                                : () async {
                                    int successCount = 0;
                                    final selectedList = selectedToAdd.toList();
                                    final ok = await modalContext
                                        .read<WardrobeViewmodel>()
                                        .addItemsToWardrobe(
                                          wardrobeId: widget.wardrobeId,
                                          itemIds: selectedList,
                                        );
                                    if (ok) {
                                      successCount = selectedList.length;
                                    }
                                    if (!modalContext.mounted) return;
                                    await modalContext
                                        .read<WardrobeViewmodel>()
                                        .fetchItemsForWardrobe(
                                          wardrobeId: widget.wardrobeId,
                                        );

                                    if (!sheetContext.mounted) return;
                                    Navigator.pop(sheetContext);

                                    if (!mounted) return;
                                    if (successCount > 0) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            "$successCount item(s) added",
                                          ),
                                        ),
                                      );
                                    } else {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            context
                                                    .read<WardrobeViewmodel>()
                                                    .error ??
                                                "Failed to add items",
                                          ),
                                        ),
                                      );
                                    }
                                  },
                            child: Text(
                              vm.isSubmitting ? "Adding..." : "Add Selected",
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showItemActions(ClothingItemModel item) async {
    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 10),
              ListTile(
                title: Text(capitalize(item.name)),
                subtitle: const Text("Choose an action"),
              ),
              if (!widget.isDefaultWardrobe)
                ListTile(
                  leading: const Icon(Icons.remove_circle_outline),
                  title: const Text("Remove from this wardrobe"),
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    await _confirmRemoveFromWardrobe(item);
                  },
                ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text("Delete item everywhere"),
                textColor: Colors.red,
                iconColor: Colors.red,
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await _confirmDeleteItem(item);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmRemoveFromWardrobe(ClothingItemModel item) async {
    final shouldRemove = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Remove item?"),
        content: Text(
          'Remove "${capitalize(item.name)}" from ${capitalize(widget.wardrobeName)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Remove"),
          ),
        ],
      ),
    );

    if (shouldRemove != true || !mounted) return;

    final firebaseUid = context.read<AuthViewmodel>().profile?.firebaseUid;
    if (firebaseUid == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("User not found")));
      return;
    }

    final ok = await context.read<WardrobeViewmodel>().removeItemFromWardrobe(
      wardrobeId: widget.wardrobeId,
      itemId: item.id,
    );

    if (!mounted) return;

    if (ok) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Item removed")));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.read<WardrobeViewmodel>().error ?? "Failed to remove item",
          ),
        ),
      );
    }
  }

  Future<void> _confirmDeleteItem(ClothingItemModel item) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Delete item permanently?"),
        content: Text(
          'Delete "${capitalize(item.name)}" from your account and all wardrobes?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (shouldDelete != true || !mounted) return;

    final firebaseUid = context.read<AuthViewmodel>().profile?.firebaseUid;
    if (firebaseUid == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("User not found")));
      return;
    }

    final ok = await context.read<WardrobeViewmodel>().deleteClothingItem(
      itemId: item.id,
    );

    if (!mounted) return;

    if (ok) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Item deleted")));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.read<WardrobeViewmodel>().error ?? "Failed to delete item",
          ),
        ),
      );
    }
  }

  void _showSortBottomSheet() {
    final options = ["Recently Added", "Oldest First", "A-Z", "Z-A"];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 12),
              ...options.map((option) {
                return ListTile(
                  title: Text(option),
                  trailing: option == _selectedSort
                      ? const Icon(Icons.check, size: 18)
                      : null,
                  onTap: () {
                    setState(() => _selectedSort = option);
                    Navigator.pop(context);
                  },
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleFeatureRequest(WardrobeViewmodel vm) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "Featured Wardrobe",
          style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          "Feature this wardrobe in the community Explore tab to showcase your style? This increases your profile visibility and inspiration for others!",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Not now"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF673AB7),
            ),
            child: const Text("Confirm"),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final success = await vm.processFeaturedWardrobePayment(widget.wardrobeId);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? "Payment successful! Your request will be reviewed shortly."
              : (vm.lastActionError ?? "Failed to process payment"),
        ),
        backgroundColor: success ? const Color(0xff0AAE00) : Colors.redAccent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wardrobeVM = context.watch<WardrobeViewmodel>();
    final items = _sortedItems(wardrobeVM.selectedWardrobeItems);
    final isWardrobeLocked = wardrobeVM.wardrobes.any(
      (w) => w.id == widget.wardrobeId && w.isLocked,
    );

    return Scaffold(
      backgroundColor: const Color(0xffF2F2F2),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),

            /// ================= HEADER =================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                height: 90, // Increased height for better spacing
                child: Stack(
                  children: [
                    // Back Button (Centered in Top Row)
                    Positioned(
                      left: 0,
                      top: 0,
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(Icons.arrow_back, size: 20),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    ),

                    // Centered Title Block
                    Positioned(
                      left: 45,
                      right: 45,
                      top: 4, // Aligned with centers of Back and More buttons
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              capitalize(widget.wardrobeName),
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.manrope(
                                fontSize: 19.8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (isWardrobeLocked)
                            const Padding(
                              padding: EdgeInsets.only(left: 6),
                              child: Icon(
                                Icons.lock_rounded,
                                size: 16,
                                color: Colors.orange,
                              ),
                            ),
                        ],
                      ),
                    ),

                    // More Menu (Top Right)
                    if (!widget.readOnly && !widget.isDefaultWardrobe)
                      Positioned(
                        right: -10, // Adjust for IconButton padding
                        top: -5,
                        child: PopupMenuButton<String>(
                          onSelected: (value) async {
                            if (value == 'rename') {
                              _promptRenameWardrobe();
                            } else if (value == 'delete') {
                              _confirmDeleteWardrobe();
                            }
                          },
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'rename',
                              child: Row(
                                children: [
                                  Icon(Icons.edit_outlined, size: 20),
                                  SizedBox(width: 10),
                                  Text("Rename"),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.delete_outline,
                                    size: 20,
                                    color: Colors.red,
                                  ),
                                  SizedBox(width: 10),
                                  Text(
                                    "Delete",
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          icon: const Icon(Icons.more_vert),
                        ),
                      ),

                    // Bottom Row (Actions & Sorting)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              if (!widget.readOnly && !isWardrobeLocked) ...[
                                GestureDetector(
                                  onTap: () =>
                                      _handleFeatureRequest(wardrobeVM),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 7,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xffF3E5F5),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: Colors.purple.shade100,
                                      ),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.star_outline_rounded,
                                          size: 14,
                                          color: Colors.purple,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          "Feature",
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.purple,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: _showAddItemsSheet,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 7,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xffDFF3E3),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.add, size: 14),
                                        SizedBox(width: 2),
                                        Text(
                                          "Add Items",
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          GestureDetector(
                            onTap: _showSortBottomSheet,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _selectedSort,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.keyboard_arrow_down,
                                    size: 16,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            /// ================= GRID =================
            Expanded(
              child: wardrobeVM.isLoadingSelectedWardrobeItems && items.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : wardrobeVM.error != null && items.isEmpty
                  ? _ErrorState(
                      message: wardrobeVM.error!,
                      onRetry: () => context
                          .read<WardrobeViewmodel>()
                          .fetchItemsForWardrobe(wardrobeId: widget.wardrobeId),
                    )
                  : items.isEmpty
                  ? Center(
                      child: Text(
                        "No items in this wardrobe yet",
                        style: GoogleFonts.manrope(fontSize: 17.1),
                      ),
                    )
                  : GridView.builder(
                      padding: EdgeInsets.zero,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 1,
                            mainAxisSpacing: 1,
                          ),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final imageUrl = item.image == null
                            ? null
                            : item.image!.startsWith("http")
                            ? item.image!
                            : "${ApiConfig.serverBaseUrl}${item.image!}";

                        final tile = Container(
                          decoration: const BoxDecoration(
                            color: Color(0xffCFCFCF),
                          ),
                          child: imageUrl == null
                              ? const Center(
                                  child: Icon(Icons.checkroom_outlined),
                                )
                              : Image.network(
                                  imageUrl,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                  errorBuilder: (_, __, ___) => const Center(
                                    child: Icon(Icons.broken_image_outlined),
                                  ),
                                ),
                        );
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    (widget.readOnly || item.isLocked)
                                    ? ClothingItemDetailScreen(item: item)
                                    : EditClothingItemScreen(item: item),
                              ),
                            );
                          },
                          onLongPress: widget.readOnly
                              ? null
                              : () => _showItemActions(item),
                          child: Stack(
                            children: [
                              Positioned.fill(child: tile),
                              if (isWardrobeLocked)
                                const Positioned(
                                  right: 6,
                                  top: 6,
                                  child: Icon(
                                    Icons.lock_rounded,
                                    size: 14,
                                    color: Colors.orange,
                                  ),
                                )
                              else if (!widget.isDefaultWardrobe &&
                                  !widget.readOnly)
                                Positioned(
                                  right: 6,
                                  top: 6,
                                  child: GestureDetector(
                                    onTap: () =>
                                        _confirmRemoveFromWardrobe(item),
                                    child: const Icon(
                                      Icons.remove_circle_outline,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _promptRenameWardrobe() async {
    final controller = TextEditingController(text: widget.wardrobeName);
    final newName = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Rename wardrobe"),
          content: TextField(
            controller: controller,
            autofocus: true,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(hintText: "Wardrobe name"),
            onSubmitted: (value) => Navigator.pop(dialogContext, value.trim()),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, controller.text.trim()),
              child: const Text("Save"),
            ),
          ],
        );
      },
    );

    if (!mounted || newName == null) return;
    final trimmed = newName.trim();
    if (trimmed.isEmpty || trimmed == widget.wardrobeName) return;

    final result = await context.read<WardrobeViewmodel>().renameWardrobe(
      wardrobeId: widget.wardrobeId,
      name: trimmed,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result != null
              ? "Wardrobe renamed"
              : (context.read<WardrobeViewmodel>().error ??
                    "Failed to rename wardrobe"),
        ),
      ),
    );
  }

  Future<void> _confirmDeleteWardrobe() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Delete wardrobe?"),
        content: Text(
          'Delete "${capitalize(widget.wardrobeName)}"? Items will not be deleted, only removed from this wardrobe.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (shouldDelete != true || !mounted) return;

    final ok = await context.read<WardrobeViewmodel>().deleteWardrobe(
      wardrobeId: widget.wardrobeId,
    );

    if (!mounted) return;

    if (ok) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Wardrobe deleted")));
      Navigator.pop(context); // Go back to main list after deletion
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.read<WardrobeViewmodel>().error ??
                "Failed to delete wardrobe",
          ),
        ),
      );
    }
  }

  List<ClothingItemModel> _sortedItems(List<ClothingItemModel> source) {
    final items = List<ClothingItemModel>.from(source);

    switch (_selectedSort) {
      case "Oldest First":
        items.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case "A-Z":
        items.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
        break;
      case "Z-A":
        items.sort(
          (a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()),
        );
        break;
      case "Recently Added":
      default:
        items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
    }

    return items;
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const _ErrorState({required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 28),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 10),
            TextButton(onPressed: onRetry, child: const Text("Retry")),
          ],
        ),
      ),
    );
  }
}
