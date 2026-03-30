import 'package:fit_app/constants.dart';

import 'package:fit_app/screens/schedule/schedule_screen.dart';
import 'package:fit_app/screens/wardrobe/add_item_screen.dart';
import 'package:fit_app/screens/wardrobe/create_wardrobe_screen.dart';
import 'package:fit_app/screens/wardrobe/wardrobe_view_screen.dart';
import 'package:fit_app/viewmodels/auth_viewmodel.dart';
import 'package:fit_app/viewmodels/wardrobe_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class WardrobeScreen extends StatefulWidget {
  const WardrobeScreen({super.key});

  @override
  State<WardrobeScreen> createState() => _WardrobeScreenState();
}

class _WardrobeScreenState extends State<WardrobeScreen> {
  bool _loaded = false;

  Future<void> _loadWardrobeTabData() async {
    final wardrobeVM = context.read<WardrobeViewmodel>();
    await wardrobeVM.fetchWardrobes();
    await wardrobeVM.fetchClothingItems();
    await wardrobeVM.fetchWardrobePreviews();
  }

  Future<void> _showWardrobeActions({
    required int wardrobeId,
    required String wardrobeName,
    required bool isDefaultWardrobe,
  }) async {
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
                title: Text(capitalize(wardrobeName)),
                subtitle: const Text("Wardrobe actions"),
              ),
              if (!isDefaultWardrobe)
                ListTile(
                  leading: const Icon(Icons.edit_outlined),
                  title: const Text("Rename wardrobe"),
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    await _promptRenameWardrobe(
                      wardrobeId: wardrobeId,
                      currentName: wardrobeName,
                    );
                  },
                ),
              if (!isDefaultWardrobe)
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  iconColor: Colors.red,
                  textColor: Colors.red,
                  title: const Text("Delete wardrobe"),
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    await _confirmDeleteWardrobe(
                      wardrobeId: wardrobeId,
                      wardrobeName: wardrobeName,
                    );
                  },
                ),
              if (isDefaultWardrobe)
                const ListTile(
                  leading: Icon(Icons.lock_outline),
                  title: Text("Default wardrobe cannot be renamed or deleted"),
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Future<void> _promptRenameWardrobe({
    required int wardrobeId,
    required String currentName,
  }) async {
    final controller = TextEditingController(text: currentName);
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
    if (trimmed.isEmpty || trimmed == currentName) return;

    final result = await context.read<WardrobeViewmodel>().renameWardrobe(
      wardrobeId: wardrobeId,
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

  Future<void> _confirmDeleteWardrobe({
    required int wardrobeId,
    required String wardrobeName,
  }) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Delete wardrobe?"),
        content: Text(
          'Delete "${capitalize(wardrobeName)}"? Items will not be deleted, only removed from this wardrobe.',
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
      wardrobeId: wardrobeId,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? "Wardrobe deleted"
              : (context.read<WardrobeViewmodel>().error ??
                    "Failed to delete wardrobe"),
        ),
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;

    // Use current user directly from Firebase if profile is not yet loaded
    final user = context.read<AuthViewmodel>().profile;
    if (user != null) {
      _loaded = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadWardrobeTabData();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewmodel>();
    final wardrobeVM = context.watch<WardrobeViewmodel>();
    final firebaseUid = authVM.profile?.firebaseUid;
    final wardrobes = wardrobeVM.wardrobes;
    final recentItems = wardrobeVM.clothingItems.take(10).toList();

    return Scaffold(
      backgroundColor: const Color(0xffF2F2F2),
      appBar: AppBar(
        backgroundColor: const Color(0xffF2F2F2),
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 20,
        title: Text(
          "Wardrobe",
          style: GoogleFonts.caveat(fontSize: 32, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ScheduleScreen()),
              );
            },
            icon: const Icon(
              Icons.calendar_month_outlined,
              color: Colors.black,
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              /// ================= RECENTLY ADDED =================
              Text(
                "Recently Added Items",
                style: GoogleFonts.caveat(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              Row(
                children: [
                  /// ADD BUTTON
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AddItemScreen(),
                        ),
                      );
                    },
                    child: Container(
                      height: 60,
                      width: 60,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.add),
                    ),
                  ),

                  const SizedBox(width: 15),

                  /// HORIZONTAL ITEMS
                  Expanded(
                    child: SizedBox(
                      height: 80,
                      child:
                          wardrobeVM.isLoadingClothingItems &&
                              recentItems.isEmpty
                          ? const Center(child: CircularProgressIndicator())
                          : recentItems.isEmpty
                          ? Center(
                              child: Text(
                                "No items yet",
                                style: GoogleFonts.caveat(fontSize: 16),
                              ),
                            )
                          : ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: recentItems.length,
                              itemBuilder: (context, index) {
                                final item = recentItems[index];
                                final imageUrl = item.image == null
                                    ? null
                                    : item.image!.startsWith("http")
                                    ? item.image!
                                    : "${ApiConfig.serverBaseUrl}${item.image!}";

                                return Padding(
                                  padding: const EdgeInsets.only(right: 15),
                                  child: Container(
                                    width: 80,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade300,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.08,
                                          ),
                                          blurRadius: 5,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                      image: imageUrl != null
                                          ? DecorationImage(
                                              image: NetworkImage(imageUrl),
                                              fit: BoxFit.cover,
                                            )
                                          : null,
                                    ),
                                    child: imageUrl == null
                                        ? const Icon(Icons.checkroom_outlined)
                                        : null,
                                  ),
                                );
                              },
                            ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 45),

              /// ================= WARDROBE SECTION =================
              Text(
                "Wardrobe",
                style: GoogleFonts.caveat(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              if (wardrobeVM.isLoadingWardrobes && wardrobes.isEmpty)
                const Center(child: CircularProgressIndicator())
              else if (wardrobes.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    "No wardrobes found",
                    style: GoogleFonts.caveat(fontSize: 18),
                  ),
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: wardrobes.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 20,
                    crossAxisSpacing: 18,
                    childAspectRatio:
                        (MediaQuery.of(context).size.width / 2) / 280,
                  ),
                  itemBuilder: (context, index) {
                    final wardrobe = wardrobes[index];
                    final previewItems =
                        wardrobeVM.wardrobePreviewItems[wardrobe.id] ??
                        const [];
                    final previewImageUrls = previewItems
                        .map((item) => item.image)
                        .whereType<String>()
                        .map(
                          (path) => path.startsWith("http")
                              ? path
                              : "${ApiConfig.serverBaseUrl}$path",
                        )
                        .take(4)
                        .toList();
                    return WardrobeCategoryCard(
                      title: wardrobe.name,
                      isDefault: wardrobe.isDefault,
                      itemCount: wardrobe.itemCount,
                      hasItems: previewItems.isNotEmpty,
                      previewImageUrls: previewImageUrls,
                      onTap: () {
                        context.read<WardrobeViewmodel>().fetchItemsForWardrobe(
                          wardrobeId: wardrobe.id,
                        );
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => WardrobeViewScreen(
                              wardrobeId: wardrobe.id,
                              wardrobeName: wardrobe.name,
                              isDefaultWardrobe: wardrobe.isDefault,
                            ),
                          ),
                        );
                      },
                      onLongPress: () => _showWardrobeActions(
                        wardrobeId: wardrobe.id,
                        wardrobeName: wardrobe.name,
                        isDefaultWardrobe: wardrobe.isDefault,
                      ),
                    );
                  },
                ),

              if (wardrobeVM.error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          wardrobeVM.error!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                      TextButton(
                        onPressed: firebaseUid == null
                            ? null
                            : () {
                                _loadWardrobeTabData();
                              },
                        child: const Text("Retry"),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 35),

              /// ================= CREATE NEW WARDROBE =================
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CreateWardrobeScreen(),
                    ),
                  );
                },
                child: Container(
                  height: 160,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add_box_outlined, size: 40),
                      const SizedBox(height: 10),
                      Text(
                        "Create new wardrobe",
                        style: GoogleFonts.caveat(fontSize: 18),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 28),

              /// ================= ADD NEW ITEMS =================
              Text(
                "Add new items",
                style: GoogleFonts.caveat(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 16),

              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AddItemScreen()),
                  );
                },
                child: Container(
                  height: 120,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add, size: 36),
                      const SizedBox(height: 8),
                      Text(
                        "Add new items",
                        style: GoogleFonts.caveat(fontSize: 18),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

/// ================= CATEGORY CARD WIDGET =================
class WardrobeCategoryCard extends StatelessWidget {
  final String title;
  final bool isDefault;
  final int itemCount;
  final bool hasItems;
  final List<String> previewImageUrls;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const WardrobeCategoryCard({
    super.key,
    required this.title,
    this.isDefault = false,
    this.itemCount = 0,
    this.hasItems = false,
    this.previewImageUrls = const [],
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final imageSlots = List<String?>.generate(
      4,
      (index) =>
          index < previewImageUrls.length ? previewImageUrls[index] : null,
    );

    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          onLongPress: onLongPress,
          child: AspectRatio(
            aspectRatio: 1.0,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: MiniBox(
                            icon: _placeholderWardrobeIcon,
                            imageUrl: hasItems ? imageSlots[0] : null,
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: MiniBox(
                            icon: _placeholderWardrobeIcon,
                            imageUrl: hasItems ? imageSlots[1] : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: MiniBox(
                            icon: _placeholderWardrobeIcon,
                            imageUrl: hasItems ? imageSlots[2] : null,
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: MiniBox(
                            icon: _placeholderWardrobeIcon,
                            imageUrl: hasItems ? imageSlots[3] : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          isDefault ? "${capitalize(title)} (Default)" : capitalize(title),
          style: GoogleFonts.caveat(fontSize: 16, fontWeight: FontWeight.w600),
          textAlign: TextAlign.center,
        ),
        Text(
          "$itemCount item${itemCount == 1 ? "" : "s"}",
          style: const TextStyle(fontSize: 11, color: Colors.black54),
        ),
      ],
    );
  }
}

const IconData _placeholderWardrobeIcon = Icons.checkroom_outlined;

/// ================= MINI BOX =================
class MiniBox extends StatelessWidget {
  final IconData icon;
  final String? imageUrl;

  const MiniBox({super.key, required this.icon, this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade400, // keep grey background
        borderRadius: BorderRadius.circular(10),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Container(
          color: Colors.grey.shade300,
          child: imageUrl == null
              ? Icon(icon, color: Colors.grey.shade800, size: 22)
              : Image.network(
                  imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      Icon(icon, color: Colors.grey.shade800, size: 22),
                ),
        ),
      ),
    );
  }
}
